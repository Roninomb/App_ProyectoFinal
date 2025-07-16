import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

class EntrenamientoScreen extends ConsumerStatefulWidget {
  const EntrenamientoScreen({super.key});

  @override
  ConsumerState<EntrenamientoScreen> createState() =>
      _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends ConsumerState<EntrenamientoScreen>
    with SingleTickerProviderStateMixin {
  static const int duracion = 15;
  int segundosRestantes = duracion;
  Timer? _timer;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _iniciarEntrenamiento();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 120 BPM = 500ms
    )..repeat(reverse: true);

    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _iniciarEntrenamiento() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosRestantes > 0) {
        setState(() {
          segundosRestantes--;
        });
      } else {
        timer.cancel();
        _finalizarEntrenamiento();
      }
    });
  }

  void _finalizarEntrenamiento() {
    final random = Random();
    final fuerza = 60 + random.nextInt(41); // 60–100
    final pulsos = 60 + random.nextInt(41); // 60–100
    final ritmo = random.nextBool();

    print("🧪 Generado => fuerza: $fuerza, pulsos: $pulsos, ritmo: $ritmo");

    ref.read(fuerzaProvider.notifier).state = fuerza.toDouble();
    ref.read(pulsosProvider.notifier).state = pulsos;
    ref.read(ritmoProvider.notifier).state = ritmo;

    context.pushNamed('resultado');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5FA),
      appBar: AppBar(title: const Text('Entrenamiento en curso')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Presione con ritmo por 15 segundos...',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withAlpha((255 * 0.2).round()),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.pinkAccent.withAlpha((255 * 0.4).round()),
                          blurRadius: 30,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              '$segundosRestantes',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
