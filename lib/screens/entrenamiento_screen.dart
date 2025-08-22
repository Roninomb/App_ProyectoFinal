import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../providers/user_provider.dart';

class EntrenamientoScreen extends ConsumerStatefulWidget {
  const EntrenamientoScreen({super.key});

  @override
 createState() => _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends ConsumerState<EntrenamientoScreen>
    with TickerProviderStateMixin {
  static const _bgColor = Color(0xFFEFF7FD);

  bool _empezado = false;
  Timer? _antiSpam; // evita toques repetidos

  @override
  void dispose() {
    _antiSpam?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleCtrl = ref.read(bleProvider.notifier);
    final nombre = ref.watch(nombreProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bgColor,
        foregroundColor: Colors.black87,
        title: const Text('Entrenamiento'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                const SizedBox(height: 20),

                // ---- Card principal de ENTRENAMIENTO (solo animación) ----
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
                      const Row(
                        children: [
                          Icon(Icons.heat_pump_rounded, color: Color.fromARGB(115, 240, 53, 53)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Listo para comenzar',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: Center(
                          child: _empezado
                              ? const _PulseRings()   // animación en vivo
                              : const _StandbyHint(), // texto sutil antes de empezar
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ---- Botón Acción ----
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _empezado
                        ? null
                        : () async {
                            _antiSpam?.cancel();
                            _antiSpam = Timer(const Duration(seconds: 1), () {});
                            await bleCtrl.startTrainingOnce(); // envía START\n una sola vez
                            if (!mounted) return;
                            setState(() => _empezado = true);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF26464),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Comenzar entrenamiento'),
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

class _StandbyHint extends StatelessWidget {
  const _StandbyHint();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Presioná "Comenzar entrenamiento".',
      style: TextStyle(color: Colors.black54),
      textAlign: TextAlign.center,
    );
  }
}

/// Animación de pulsos concéntricos
class _PulseRings extends StatefulWidget {
  // ignore: unused_element_parameter
  const _PulseRings({super.key});
  @override
  State<_PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<_PulseRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 3; i++) _Ring(anim: _c, delay: i * 0.2),
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final Animation<double> anim;
  final double delay;
  const _Ring({required this.anim, required this.delay});

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: anim,
      curve: Interval(delay, (delay + 0.8).clamp(0, 1.0), curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (_, __) {
        final v = curved.value; // 0..1
        final scale = 0.6 + 0.6 * v; // 0.6 → 1.2
        final opacity = 1.0 - v;     // 1 → 0
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
