import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../providers/user_provider.dart';

class PreEntrenamientoScreen extends ConsumerWidget {
  const PreEntrenamientoScreen({super.key});

  static const _bgColor = Color(0xFFEFF7FD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleProvider);
    final bleCtrl = ref.read(bleProvider.notifier);
    final nombre = ref.watch(nombreProvider);

    // Conexión automática al entrar en la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!ble.connected && !ble.scanning && !ble.connecting) {
        await bleCtrl.scanAndConnect(
          scanTimeout: const Duration(seconds: 10),
          connectTimeout: const Duration(seconds: 10),
          namePrefix: "NeoRCP",
        );
      }
      // Cuando se conecta, navega directo a entrenamiento
      // ignore: use_build_context_synchronously
      if (ref.read(bleProvider).connected && ModalRoute.of(context)?.isCurrent == true) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/entrenamiento');
      }
    });

    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hola, $nombre',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ble.connected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth,
                            color: ble.connected ? Colors.teal : Colors.black45,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ble.connected
                                  ? 'Bluetooth listo'
                                  : 'Conectando…',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          // La animación SIEMPRE visible
                          const _PulseDot(),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(minHeight: 3),
                      ),
                      if (ble.error?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 10),
                        _Hint(
                          text: 'Error BLE: ${ble.error}',
                          color: Colors.red,
                          icon: Icons.error_outline,
                        ),
                      ],
                      if (ble.connectTimedOut) ...[
                        const SizedBox(height: 10),
                        const _Hint(
                          text:
                              'Timeout de conexión. Activá Bluetooth y acercá el teléfono al ESP32.',
                          color: Colors.red,
                          icon: Icons.timer_off,
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
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

/// Dot pulsante SIEMPRE visible
class _PulseDot extends StatefulWidget {
  // ignore: unused_element_parameter
  const _PulseDot({super.key});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.8, end: 1.05)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _opacity = Tween(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(left: 6),
          decoration: const BoxDecoration(
            color: Colors.teal,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Hint({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
