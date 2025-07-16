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
      context.pushNamed('entrenamiento');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = ref.watch(nombreProvider);
    final estado = ref.watch(bleStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PreEntrenamiento',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C2E45),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¡Hola, $nombre!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2E45),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Coloque ambas manos sobre el tórax y presione con ritmo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                if (estado == BLEStatus.connecting)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Conectando con el dispositivo BLE...",
                        style: TextStyle(fontFamily: 'Inter'),
                      ),
                    ],
                  ),

                if (estado == BLEStatus.failed)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      '⚠️ No se pudo conectar al dispositivo BLE.\nSe usará simulación.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _irAEntrenamiento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26464),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Iniciar entrenamiento'),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _irAEntrenamiento,
                  icon: const Icon(Icons.email),
                  label: const Text('Enviar datos por email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF444444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
