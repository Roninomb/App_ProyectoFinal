import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/ble_provider.dart';
import '../ble/ble_manager.dart';
import 'dart:async';

class PreEntrenamientoScreen extends ConsumerStatefulWidget {
  const PreEntrenamientoScreen({super.key});

  @override
  ConsumerState<PreEntrenamientoScreen> createState() =>
      _PreEntrenamientoScreenState();
}

class _PreEntrenamientoScreenState
    extends ConsumerState<PreEntrenamientoScreen> {
  final BleManager bleManager = BleManager();
  StreamSubscription? _bleScanSubscription;

  @override
  void initState() {
    super.initState();
    _intentarConexionBLE();
  }

  Future<void> _intentarConexionBLE() async {
    ref.read(bleStatusProvider.notifier).state = BLEStatus.connecting;

    final conectado = await bleManager.conectar(
      onData: (data) => print("📥 Datos recibidos: $data"),
      onScanSubscriptionCreated: (sub) => _bleScanSubscription = sub,
    );

    ref.read(bleStatusProvider.notifier).state =
        conectado ? BLEStatus.connected : BLEStatus.failed;
  }

  void _irAEntrenamiento() async {
    await _bleScanSubscription?.cancel();
    if (mounted) {
      context.pushNamed('entrenamiento'); // 🔁 IR SIEMPRE A ENTRENAMIENTO
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = ref.watch(nombreProvider);
    final estado = ref.watch(bleStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Hola, $nombre!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Coloque ambas manos sobre el tórax y presione con ritmo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (estado == BLEStatus.connecting)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Conectando con el dispositivo BLE..."),
                ],
              ),

            if (estado == BLEStatus.failed)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  '⚠️ No se pudo conectar al dispositivo BLE.\nSe usará simulación.',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _irAEntrenamiento,
              child: const Text('Iniciar entrenamiento'),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _irAEntrenamiento, // 🔁 MISMA FUNCIÓN
              icon: const Icon(Icons.email),
              label: const Text('Enviar datos por email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
