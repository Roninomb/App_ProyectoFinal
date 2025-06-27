import "package:permission_handler/permission_handler.dart";

Future<void> pedirPermisos() async {
  await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();
}
