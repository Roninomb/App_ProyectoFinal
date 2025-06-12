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

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Entrenamiento completado', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('👤 Nombre: $nombre'),
            Text('📧 Email: $email'),
            const Divider(height: 32),
            Text('📊 Resultados:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('💪 Fuerza promedio: ${fuerza.toStringAsFixed(2)} N'),
            Text('❤️ Pulsos promedio: $pulsos bpm'),
            Text('🧠 Ritmo: ${ritmo ? 'Correcto' : 'Incorrecto'}'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Enviar reporte por email'),
                onPressed: () async {
                  try {
                    await enviarReportePorEmail(
                      nombre: nombre,
                      email: email,
                      fuerza: fuerza,
                      pulsos: pulsos,
                      ritmo: ritmo,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📨 Reporte enviado por email')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error al enviar: $e')),
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
