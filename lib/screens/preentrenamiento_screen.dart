import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PreTrainScreen extends StatelessWidget {
  final String nombre;
  final String email;

  const PreTrainScreen({
    super.key,
    required this.nombre,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Hola, $nombre!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Coloque ambas manos sobre el torax y presione con ritmo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.pushNamed('entrenamiento', extra: {
                  'nombre': nombre,
                  'email': email,
                });
              },
              child: const Text('Iniciar entrenamiento'),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                context.pushNamed('resultado', extra: {
                  'nombre': nombre,
                  'email': email,
                  'fuerza': 42.5,
                  'pulsos': 110,
                  'ritmo': true,
                });
              },
              child: const Text('Finalizar'),
            ),
          ],
        ),
      ),
    );
  }
}
