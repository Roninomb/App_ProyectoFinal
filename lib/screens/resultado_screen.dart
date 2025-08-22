import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../providers/training_provider.dart'; // Importa el provider central
import '../services/email_service.dart';

class ResultadoScreen extends ConsumerWidget {
  const ResultadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(nombreProvider);
    final email = ref.watch(emailProvider);
    final training = ref.watch(trainingProvider); // Usa el provider central

    Future<void> enviarEmail() async {
      if (email.trim().isEmpty || nombre.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre o el email están vacíos.')),
        );
        return;
      }

      try {
        await enviarReportePorEmail(
          nombre: nombre,
          email: email,
          fuerza: training.fuerza?.toString() ?? '',
          pulsos: training.pulsos?.toString() ?? '',
          ritmo: training.ritmo?.toString() ?? '',
        );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📩 Reporte enviado correctamente')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al enviar email: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Resultado del entrenamiento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¡Buen trabajo, $nombre!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: "inter",
                  ),
                ),
                const SizedBox(height: 24),

                // Métricas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💪 Fuerza efectiva: ${training.fuerza ?? '-'} %'),
                    const SizedBox(height: 8),
                    Text('❤️ Pulsos efectivos: ${training.pulsos ?? '-'} %'),
                    const SizedBox(height: 8),
                    Text('🕒 Ritmo: ${training.ritmo ?? '-'}'),
                  ],
                ),

                const SizedBox(height: 32),

                // Botón (child al final para cumplir el lint)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: enviarEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '📧 Enviar reporte por email',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
