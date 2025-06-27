import "dart:convert";
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleManager {
  final flutterReactiveBle = FlutterReactiveBle();
  late DiscoveredDevice device;
  Future<void> conectar(Function(Map<String, String>) onData) async{
    await flutterReactiveBle.scanForDevices(
      withServices: [Uuid.parse("6400001-B5A3-F33-E0A9-E50E24DCCA9E")], 
      ).listen((d) async{
        if(d.name == "NeoRcp"){
          device = d;
          await flutterReactiveBle.connectToDevice(id: device.id).first;
          _escuchar(onData);
        }
      }).asFuture();
     }
     void _escuchar(Function(Map<String, String>) onData) {
      final characteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse("6400001-B5A3-F33-E0A9-E50E24DCCA9E"),
        characteristicId: Uuid.parse("6400002-B5A3-F33-E0A9-E50E24DCCA9E"),
        deviceId: device.id,
      );
      flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data){
        final decoded = utf8.decode(data);
        final parsed = Map.fromEntries(
          decoded.split(",").map((e){
            final partes = e.split("=");
            return MapEntry(partes[0], partes[1]);
          })
        );
        onData(parsed);
      });
     }
    } 
  
      

     