import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';

class PreEntrenamientoScreen extends ConsumerWidget {
  const PreEntrenamientoScreen({super.key});

  static const _bgColor = Color(0xFFEFF7FD);
  static const _ctaColor = Color(0xFFF26161);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleProvider);
    final bleCtrl = ref.read(bleProvider.notifier); // <- NOTIFIER (controlador)

    Future<void> connectBle() async {
      await bleCtrl.scanAndConnect(
        scanTimeout: const Duration(seconds: 10),
        connectTimeout: const Duration(seconds: 10),
        namePrefix: "NeoRCP",
      );
      if (!context.mounted) return;

      if (ref.read(bleProvider).connected) {
        await bleCtrl.subscribeResult();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('BLE listo')));
      } else if (ble.error?.isNotEmpty ?? false) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error BLE: ${ble.error}')));
      }
    }

    // 👉 Enviar START y navegar a /entrenamiento
    Future<void> startTraining() async {
      if (!ref.read(bleProvider).connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay conexión BLE')),
        );
        return;
      }
      await bleCtrl.startTraining();                 // <-- método del notifier
      if (!context.mounted) return;                  // evita warning use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrenamiento iniciado')),
      );
      Navigator.of(context).pushReplacementNamed('/entrenamiento');
    }

    final connected = ble.connected;
    final busy = ble.scanning || ble.connecting;

    final primaryLabel =
        connected ? 'Comenzar entrenamiento' : 'Conectar por Bluetooth';
    final Future<void> Function() primaryAction =
        connected ? startTraining : connectBle;

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
                            connected
                                ? Icons.bluetooth_connected
                                : Icons.bluetooth,
                            color: connected ? Colors.teal : Colors.black45,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              connected
                                  ? 'Bluetooth listo'
                                  : (ble.scanning
                                      ? 'Buscando dispositivo…'
                                      : (ble.connecting
                                          ? 'Conectando…'
                                          : 'Bluetooth listo')),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: (ble.scanning || ble.connecting)
                                ? const _PulseDot(key: ValueKey('dot'))
                                : const SizedBox(width: 16, key: ValueKey('nodot')),
                          ),
                        ],
                      ),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: (ble.scanning || ble.connecting)
                            ? const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: LinearProgressIndicator(minHeight: 3),
                              )
                            : const SizedBox(height: 12),
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

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: busy ? null : primaryAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _ctaColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          child: Text(primaryLabel),
                        ),
                      ),
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

/// Dot pulsante
class _PulseDot extends StatefulWidget {
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
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
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
