import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(nombreProvider);
    final email = ref.watch(emailProvider);

    final camposValidos =
        nombre.trim().isNotEmpty && email.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bienvenido a la app de RCP',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  ref.read(nombreProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) =>
                  ref.read(emailProvider.notifier).state = value,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: camposValidos
                  ? () => context.pushNamed('pretrain')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    camposValidos ? Colors.deepPurple : Colors.grey[300],
                foregroundColor:
                    camposValidos ? Colors.white : Colors.black45,
              ),
              child: const Text('Comenzar entrenamiento'),
            ),
          ],
        ),
      ),
    );
  }
}
