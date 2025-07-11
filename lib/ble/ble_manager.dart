import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleManager {
  final flutterReactiveBle = FlutterReactiveBle();
  late DiscoveredDevice device;

  Future<bool> conectar({
    required Function(Map<String, String>) onData,
    required void Function(StreamSubscription<DiscoveredDevice>) onScanSubscriptionCreated,
  }) async {
    final completer = Completer<bool>();
    late StreamSubscription<DiscoveredDevice> scanSub;

    scanSub = flutterReactiveBle
        .scanForDevices(
          withServices: [Uuid.parse("6400001-B5A3-F33-E0A9-E50E24DCCA9E")],
          scanMode: ScanMode.lowLatency,
        )
        .listen((d) async {
      if (d.name == "NeoRcp") {
        device = d;
        await scanSub.cancel();
        await flutterReactiveBle.connectToDevice(id: d.id).first;
        _escuchar(onData);
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    onScanSubscriptionCreated(scanSub);

    Future.delayed(const Duration(seconds: 10), () async {
      if (!completer.isCompleted) {
        await scanSub.cancel();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  void _escuchar(Function(Map<String, String>) onData) {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse("6400001-B5A3-F33-E0A9-E50E24DCCA9E"),
      characteristicId: Uuid.parse("6400002-B5A3-F33-E0A9-E50E24DCCA9E"),
      deviceId: device.id,
    );

    flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((data) {
      final decoded = utf8.decode(data);
      final parsed = Map.fromEntries(
        decoded.split(",").map((e) {
          final partes = e.split("=");
          return MapEntry(partes[0], partes[1]);
        }),
      );
      onData(parsed);
    });
  }
}
