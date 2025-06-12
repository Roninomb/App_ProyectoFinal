import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

class PreEntrenamientoScreen extends ConsumerWidget {
  const PreEntrenamientoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(nombreProvider);

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
              'Coloque ambas manos sobre el tórax y presione con ritmo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.pushNamed('entrenamiento');
              },
              child: const Text('Iniciar entrenamiento'),
            ),
          ],
        ),
      ),
    );
  }
}
