// lib/providers/ble_provider.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// UUIDs (deben coincidir con el ESP32)
final _serviceUuid    = Uuid.parse("f0000001-0451-4000-b000-000000000000");
final _ctrlCharUuid   = Uuid.parse("f0000002-0451-4000-b000-000000000000"); // Write
final _resultCharUuid = Uuid.parse("f0000003-0451-4000-b000-000000000000"); // Notify

final bleProvider =
    StateNotifierProvider<BleController, BleState>((ref) => BleController());

class BleState {
  final bool scanning;
  final bool connecting;
  final bool connected;
  final DiscoveredDevice? device;
  final String? lastJson;   // JSON reensamblado por '\n'
  final String? error;
  final bool connectTimedOut;

  const BleState({
    this.scanning = false,
    this.connecting = false,
    this.connected = false,
    this.device,
    this.lastJson,
    this.error,
    this.connectTimedOut = false,
  });

  BleState copyWith({
    bool? scanning,
    bool? connecting,
    bool? connected,
    DiscoveredDevice? device,
    String? lastJson,
    String? error,
    bool? connectTimedOut,
  }) =>
      BleState(
        scanning: scanning ?? this.scanning,
        connecting: connecting ?? this.connecting,
        connected: connected ?? this.connected,
        device: device ?? this.device,
        lastJson: lastJson ?? this.lastJson,
        error: error,
        connectTimedOut: connectTimedOut ?? this.connectTimedOut,
      );

  @override
  String toString() =>
      'BleState(scan:$scanning, conn:$connecting, ok:$connected, '
      'dev:${device?.name}/${device?.id}, err:$error, lastJson:$lastJson)';
}

class BleController extends StateNotifier<BleState> {
  BleController() : super(const BleState());

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  // Buffer para reensamblar por '\n'
  String _rxBuf = '';

  // Deduplicación de START
  bool _startSent = false;
  Future<void>? _startInFlight;

  // ---------- Helpers ----------
  bool _guardWeb(String action) {
    if (kIsWeb) {
      state = state.copyWith(error: 'BLE no está soportado en Web (acción: $action).');
      return true;
    }
    return false;
  }

  Future<bool> _ensurePermissions() async {
    final res = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // útil en Android <= 11
    ].request();

    final ok = res.values.every((s) => s.isGranted);
    if (!ok) {
      state = state.copyWith(error: 'Permisos BLE rechazados.');
      return false;
    }
    return true;
  }

  Future<bool> _waitUntilReady({Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final s = await _ble.statusStream.timeout(timeout).first;
      if (s == BleStatus.ready) return true;
      state = state.copyWith(error: _statusToMessage(s));
      return false;
    } on TimeoutException {
      state = state.copyWith(error: 'No se pudo leer el estado de Bluetooth.');
      return false;
    }
  }

  String _statusToMessage(BleStatus s) {
    switch (s) {
      case BleStatus.poweredOff:
        return 'Bluetooth desactivado.';
      case BleStatus.locationServicesDisabled:
        return 'Ubicación desactivada (requerida para escanear).';
      case BleStatus.unauthorized:
        return 'Permisos BLE no autorizados.';
      case BleStatus.unsupported:
        return 'BLE no soportado en este dispositivo.';
      case BleStatus.ready:
        return '';
      case BleStatus.unknown:
        return 'Estado BLE desconocido.';
    }
  }

  // ---------- API pública ----------
  void clearLastJson() => state = state.copyWith(lastJson: null, error: null);

  // ---------- Escaneo ----------
  Future<void> startScan({
    String namePrefix = 'NeoRCP',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_guardWeb('scan')) return;

    await _scanSub?.cancel();
    state = state.copyWith(
      scanning: false,
      error: null,
      connectTimedOut: false,
      device: null,
    );

    if (!await _ensurePermissions()) return;
    if (!await _waitUntilReady()) return;

    state = state.copyWith(scanning: true);
    final found = Completer<void>();

    _scanSub = _ble
        .scanForDevices(withServices: const [], scanMode: ScanMode.lowLatency)
        .listen(
      (d) {
        if (d.name.isNotEmpty && d.name.startsWith(namePrefix)) {
          _scanSub?.cancel();
          state = state.copyWith(scanning: false, device: d);
          if (!found.isCompleted) found.complete();
        }
      },
      onError: (e) {
        state = state.copyWith(error: 'Error de escaneo: $e', scanning: false);
        if (!found.isCompleted) found.complete();
      },
    );

    Timer(timeout, () async {
      if (!found.isCompleted) {
        await stopScan();
        state = state.copyWith(
          error: state.error ?? 'No se encontró el dispositivo.',
          scanning: false,
        );
        found.complete();
      }
    });

    await found.future;
  }

  // ---------- Conexión ----------
  Future<void> connectWithTimeout({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_guardWeb('connect')) return;

    final d = state.device;
    if (d == null) {
      state = state.copyWith(error: 'No hay dispositivo seleccionado.');
      return;
    }

    await _connSub?.cancel();
    state = state.copyWith(error: null, connectTimedOut: false, connecting: true);

    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('timeout'));
      }
    });

    _connSub = _ble.connectToDevice(id: d.id, connectionTimeout: timeout).listen(
      (u) async {
        switch (u.connectionState) {
          case DeviceConnectionState.connected:
            state = state.copyWith(connected: true, connecting: false);

            // 👇 Ajustes de enlace ANTES de suscribirse (mejor MTU/latencia)
            try { await _ble.requestMtu(deviceId: d.id, mtu: 185); } catch (_) {}
            try {
              await _ble.requestConnectionPriority(
                deviceId: d.id,
                priority: ConnectionPriority.highPerformance,
              );
            } catch (_) {}

            await subscribeResult(); // habilita CCCD y escucha resultados
            if (!completer.isCompleted) completer.complete();
            break;
          case DeviceConnectionState.disconnected:
            state = state.copyWith(connected: false, connecting: false);
            break;
          default:
            state = state.copyWith(connecting: true);
        }
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
        state = state.copyWith(
          error: 'Error de conexión: $e',
          connected: false,
          connecting: false,
        );
      },
    );

    try {
      await completer.future;
    } on TimeoutException {
      state =
          state.copyWith(connectTimedOut: true, connected: false, connecting: false);
      await cancelConnection();
    } finally {
      timer.cancel();
    }
  }

  Future<void> scanAndConnect({
    Duration scanTimeout = const Duration(seconds: 30),
    Duration connectTimeout = const Duration(seconds: 30),
    String namePrefix = 'NeoRCP',
  }) async {
    await startScan(namePrefix: namePrefix, timeout: scanTimeout);
    if (state.device == null) return;
    await connectWithTimeout(timeout: connectTimeout);
  }

  // ---------- Notificaciones (reensamble por '\n') ----------
  Future<void> subscribeResult() async {
    if (_guardWeb('subscribe')) return;

    final d = state.device;
    if (d == null) return;

    await _notifySub?.cancel();
    _rxBuf = '';

    final c = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _resultCharUuid,
      deviceId: d.id,
    );

    _notifySub = _ble.subscribeToCharacteristic(c).listen(
      (data) {
        _rxBuf += utf8.decode(data, allowMalformed: true);
        int nl;
        while ((nl = _rxBuf.indexOf('\n')) != -1) {
          final msg = _rxBuf.substring(0, nl).trim();
          _rxBuf = _rxBuf.substring(nl + 1);
          if (msg.isNotEmpty) {
            // 👇 LOG de cada paquete reensamblado (ACK / tick / final)
            // ignore: avoid_print
            print('[BLE][notify] $msg');

            state = state.copyWith(lastJson: msg);
          }
        }
      },
      onError: (e) => state = state.copyWith(error: 'Error de notificación: $e'),
    );
  }

  // ---------- Comandos ----------
  Future<void> sendCommand(String cmd) async {
    if (_guardWeb('write')) return;

    final d = state.device;
    if (d == null) return;

    final c = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _ctrlCharUuid,
      deviceId: d.id,
    );

    final bytes = utf8.encode(cmd.endsWith('\n') ? cmd : '$cmd\n');
    await _ble.writeCharacteristicWithResponse(c, value: bytes);
    // Si tu característica soporta sin respuesta:
    // await _ble.writeCharacteristicWithoutResponse(c, value: bytes);
  }

  Future<void> startTraining() => sendCommand('START');

  /// Envía START una sola vez por sesión y limpia resultados previos.
  Future<void> startTrainingOnce() {
    clearLastJson(); // ✅ evita navegar por ACK/JSON viejo
    if (_startSent) return Future.value();
    if (_startInFlight != null) return _startInFlight!;
    return _startInFlight = startTraining().whenComplete(() {
      _startSent = true;
      _startInFlight = null;
    });
  }

  // ---------- Cancelaciones / limpieza ----------
  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    state = state.copyWith(scanning: false);
  }

  Future<void> cancelConnection() async {
    await _connSub?.cancel();
    _connSub = null;
    state = state.copyWith(connecting: false, connected: false);
  }

  Future<void> abortAll() async {
    if (_guardWeb('abortAll')) return;

    await stopScan();
    await cancelConnection();
    await _notifySub?.cancel();
    _notifySub = null;

    _rxBuf = '';
    _startSent = false;
    _startInFlight = null;

    state = state.copyWith(
      scanning: false,
      connecting: false,
      connected: false,
      connectTimedOut: false,
      error: null,
      lastJson: null,
    );
  }

  Future<void> disconnect() async {
    if (_guardWeb('disconnect')) return;

    await _notifySub?.cancel();
    _notifySub = null;
    await _connSub?.cancel();
    _connSub = null;

    _rxBuf = '';
    _startSent = false;
    _startInFlight = null;

    state = state.copyWith(
      connected: false,
      connecting: false,
      lastJson: null,
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    super.dispose();
  }
}
