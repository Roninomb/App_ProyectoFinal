import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../services/email_service.dart';

class ResultadoScreen extends ConsumerWidget {
  const ResultadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(nombreProvider);
    final email = ref.watch(emailProvider);
    final fuerza = ref.watch(fuerzaProvider);
    final pulsos = ref.watch(pulsosProvider);
    final ritmo = ref.watch(ritmoProvider);

    Future<void> enviarEmail() async {
      if (email.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El email está vacío.')),
        );
        return;
      }

      try {
        await enviarReportePorEmail(
          nombre: nombre,
          email: email,
          fuerza: fuerza,
          pulsos: pulsos,
          ritmo: ritmo,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar email: $e')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resultado del entrenamiento')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¡Buen trabajo, $nombre!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text('💪 Fuerza efectiva: ${fuerza.toStringAsFixed(1)} %'),
            Text('❤️ Pulsos efectivos: $pulsos %'),
            Text('Ritmo: ${ritmo ? 'Correcto' : 'Incorrecto'}'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: enviarEmail,
              icon: const Icon(Icons.email),
              label: const Text('Enviar reporte por email'),
            ),
          ],
        ),
      ),
    );
  }
}
