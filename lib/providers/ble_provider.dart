import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

/// UUIDs de servicio/características (ajusta si usás otros)
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
  final String? lastJson;
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
}

class BleController extends StateNotifier<BleState> {
  BleController() : super(const BleState());

  final _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  // ---------- Permisos + estado Bluetooth ----------
  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);
    if (!allGranted) {
      state = state.copyWith(error: "Permisos BLE rechazados.");
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
      state = state.copyWith(error: "No se pudo leer el estado de Bluetooth.");
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

  // ---------- Escaneo / Conexión ----------
  Future<void> startScan({
    String namePrefix = "NeoRCP",
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Reset previo
    await _scanSub?.cancel();
    state = state.copyWith(scanning: false, error: null, connectTimedOut: false);

    // 1) permisos
    if (!await _ensurePermissions()) return;

    // 2) estado BT
    if (!await _waitUntilReady()) return;

    // 3) escaneo con timeout real
    state = state.copyWith(scanning: true);


    await Future.delayed(const Duration(seconds: 2));

    final found = Completer<void>();

    _scanSub = _ble.scanForDevices(withServices: [_serviceUuid]).listen(
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

    await found.future; // termina cuando cierra el scan (encontró/timeout/error)
  }

  Future<void> connectWithTimeout({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final d = state.device;
    if (d == null) {
      state = state.copyWith(error: "No hay dispositivo seleccionado.");
      return;
    }
    await _connSub?.cancel();
    state = state.copyWith(error: null, connectTimedOut: false, connecting: true);

    final completer = Completer<void>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException("timeout"));
      }
    });

    _connSub = _ble.connectToDevice(id: d.id, connectionTimeout: timeout).listen(
      (u) {
        switch (u.connectionState) {
          case DeviceConnectionState.connected:
            state = state.copyWith(connected: true, connecting: false);
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
      state = state.copyWith(connectTimedOut: true, connected: false, connecting: false);
      await cancelConnection();
    } finally {
      timer.cancel();
    }
  }

  Future<void> scanAndConnect({
    Duration scanTimeout = const Duration(seconds: 10),
    Duration connectTimeout = const Duration(seconds: 10),
    String namePrefix = "NeoRCP",
  }) async {
    await startScan(namePrefix: namePrefix, timeout: scanTimeout);
    if (state.device == null) return; // no intentes conectar si no hay device
    await connectWithTimeout(timeout: connectTimeout);
  }

  Future<void> subscribeResult() async {
    final d = state.device;
    if (d == null) return;
    await _notifySub?.cancel();

    final c = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _resultCharUuid,
      deviceId: d.id,
    );
    _notifySub = _ble.subscribeToCharacteristic(c).listen(
      (data) => state = state.copyWith(lastJson: utf8.decode(data)),
      onError: (e) => state = state.copyWith(error: 'Error de notificación: $e'),
    );
  }

  Future<void> sendCommand(String cmd) async {
    final d = state.device;
    if (d == null) return;
    final c = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _ctrlCharUuid,
      deviceId: d.id,
    );
    await _ble.writeCharacteristicWithResponse(c, value: utf8.encode(cmd));
  }

    Future<void> startTraining() => sendCommand("START");
  

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

  /// Corta scan + connect + notificaciones y deja el estado listo para reintentar
  Future<void> abortAll() async {
    await stopScan();
    await cancelConnection();
    await _notifySub?.cancel();
    _notifySub = null;

    state = state.copyWith(
      scanning: false,
      connecting: false,
      connected: false,
      connectTimedOut: false,
      error: null,
      // Si querés limpiar también el device:
      // device: null,
    );
  }

  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    await _connSub?.cancel();
    _connSub = null;
    state = state.copyWith(connected: false, connecting: false);
  }
  

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _notifySub?.cancel();
    super.dispose();
  }
}
