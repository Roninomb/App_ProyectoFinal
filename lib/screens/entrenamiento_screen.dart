// lib/screens/entrenamiento_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

class EntrenamientoScreen extends ConsumerStatefulWidget {
  const EntrenamientoScreen({super.key});

  @override
  ConsumerState<EntrenamientoScreen> createState() => _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends ConsumerState<EntrenamientoScreen> {
  static const int duracionEntrenamiento = 10; // segundos
  late Timer _timer;
  int segundosRestantes = duracionEntrenamiento;
  bool entrenamientoFinalizado = false;

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosRestantes == 1) {
        setState(() {
          entrenamientoFinalizado = true;
          _timer.cancel();
        });
      } else {
        setState(() {
          segundosRestantes--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _finalizarEntrenamiento() {
    final random = Random();
    final fuerza = 70 + random.nextInt(31); // 70–100%
    final pulsos = 70 + random.nextInt(31); // 70–100%
    final ritmoCorrecto = random.nextBool();

    ref.read(fuerzaProvider.notifier).state = fuerza.toDouble();
    ref.read(pulsosProvider.notifier).state = pulsos;
    ref.read(ritmoProvider.notifier).state = ritmoCorrecto;

    context.pushNamed('resultado');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento activo')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Entrenamiento en curso...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '$segundosRestantes s',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: entrenamientoFinalizado ? _finalizarEntrenamiento : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: entrenamientoFinalizado ? Colors.red : Colors.grey,
              ),
              child: const Text('Finalizar entrenamiento'),
            ),
          ],
        ),
      ),
    );
  }
}
