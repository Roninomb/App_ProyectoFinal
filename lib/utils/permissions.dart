import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<Map<Permission, PermissionStatus>>? _inFlight;

/// Pide los permisos BLE de forma serializada y multiplataforma.
/// Devuelve true si TODOS fueron concedidos.
Future<bool> pedirPermisos() async {
  // Si ya hay un request corriendo, reusar ese Future.
  if (_inFlight != null) {
    final res = await _inFlight!;
    return _allGranted(res);
  }

  final permisos = <Permission>[
    if (Platform.isAndroid) ...[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // requerido para escanear en Android ≤ 11
    ] else ...[
      Permission.bluetooth,         // iOS
      Permission.locationWhenInUse,
    ],
  ];

  _inFlight = permisos.request(); // una sola solicitud, todos juntos
  try {
    final res = await _inFlight!;
    // Manejo opcional: si alguno quedó "permanentlyDenied", abrir ajustes.
    if (res.values.any((s) => s.isPermanentlyDenied)) {
      await openAppSettings();
    }
    return _allGranted(res);
  } finally {
    _inFlight = null;
  }
}

bool _allGranted(Map<Permission, PermissionStatus> m) =>
    m.values.every((s) => s.isGranted);
