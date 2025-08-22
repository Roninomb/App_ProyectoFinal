import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleManager {
  final flutterReactiveBle = FlutterReactiveBle();
  late DiscoveredDevice device;

  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  // Conectar al dispositivo "NeoRcp"
  Future<bool> conectar() async {
    final completer = Completer<bool>();
    late StreamSubscription<DiscoveredDevice> scanSub;

    scanSub = flutterReactiveBle
        .scanForDevices(
          withServices: [Uuid.parse("00006400-0000-1000-8000-00805f9b34fb")], // UUID válido
          scanMode: ScanMode.lowLatency,
        )
        .listen((d) async {
      if (d.name == "NeoRcp") {
        device = d;
        await scanSub.cancel();

        _connectionSub = flutterReactiveBle.connectToDevice(id: d.id).listen(
          (update) {
            if (update.connectionState == DeviceConnectionState.connected &&
                !completer.isCompleted) {
              completer.complete(true);
            }
            if (update.connectionState == DeviceConnectionState.disconnected &&
                !completer.isCompleted) {
              completer.complete(false);
            }
          },
        );
      }
    });

    // Timeout a los 10s
    Future.delayed(const Duration(seconds: 10), () async {
      if (!completer.isCompleted) {
        await scanSub.cancel();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  // Escuchar datos durante el entrenamiento
  void escucharDatos(Function(Map<String, String>) onData) {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse("00006400-0000-1000-8000-00805f9b34fb"),
      characteristicId: Uuid.parse("00006401-0000-1000-8000-00805f9b34fb"),
      deviceId: device.id,
    );

    _dataSubscription = flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((data) {
      try {
        final decoded = utf8.decode(data);
        final parsed = <String, String>{};
        for (final part in decoded.split(",")) {
          final kv = part.split("=");
          if (kv.length == 2) {
            parsed[kv[0].trim()] = kv[1].trim();
          }
        }
        onData(parsed);
      } catch (e) {
        // ignore: avoid_print
        print("Error decodificando datos BLE: $e");
      }
    });
  }

  // Cancelar escucha al finalizar entrenamiento
  Future<void> cancelarEscucha() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
  }
}
