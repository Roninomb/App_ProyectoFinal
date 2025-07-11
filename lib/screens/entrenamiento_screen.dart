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

class _EntrenamientoScreenState extends ConsumerState<EntrenamientoScreen> {
  static const int duracion = 15;
  int segundosRestantes = duracion;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarEntrenamiento();
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
    final fuerza = 60 + random.nextInt(41);  // 60–100
    final pulsos = 60 + random.nextInt(41);  // 60–100
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(height: 24),
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
