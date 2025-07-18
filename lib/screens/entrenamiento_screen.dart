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
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Entrenamiento en curso',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C2E45),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Presione con ritmo por 15 segundos...',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withAlpha((0.15 * 255).round()),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withAlpha(60),
                            blurRadius: 50,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
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
      ),
    );
  }
}
