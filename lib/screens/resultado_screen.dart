import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../services/email_service.dart';

class ResultadoScreen extends ConsumerWidget {
  const ResultadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final nombre = ref.watch(nombreProvider);
    ref.watch(emailProvider);
    final fuerza = ref.watch(fuerzaProvider);
    final pulsos = ref.watch(pulsosProvider);
    final ritmo = ref.watch(ritmoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen del entrenamiento')),
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
              elevation: 4,
              child: ListTile(
                title: const Text('Fuerza promedio'),
                subtitle: Text('${fuerza.toStringAsFixed(1)} N'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: ListTile(
                title: const Text('Pulsos por minuto'),
                subtitle: Text('$pulsos bpm'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: ListTile(
                title: const Text('Ritmo'),
                subtitle: Text(ritmo ? 'Correcto' : 'Incorrecto'),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  await enviarReportePorEmail(ref);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📩 Reporte enviado exitosamente')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error al enviar: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Enviar reporte por correo'),
            ),
          ],
        ),
      ),
    );
  }
}
