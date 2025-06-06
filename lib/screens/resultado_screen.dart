import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultadoScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ResultadoScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final pulsos = data['pulsos'] ?? 0;
    final ritmoCorrecto = data['ritmo'] ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resumen del entrenamiento',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                title: const Text('Fuerza'),
                subtitle: Text('correcta'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Pulsos promedio'),
                subtitle: Text('$pulsos bpm'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Ritmo del metrónomo'),
                subtitle: Text(ritmoCorrecto ? 'Correcto' : 'Incorrecto'),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                context.goNamed('home');
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
