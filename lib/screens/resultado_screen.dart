import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';
import '../providers/training_provider.dart';
import '../services/email_service.dart';

class ResultadoScreen extends ConsumerWidget {
  const ResultadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(nombreProvider);
    final email = ref.watch(emailProvider);
    final training = ref.watch(trainingProvider);

    String fmtPct(num? v) => (v == null) ? '-' : v.toString();

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
          ritmo: training.total != null
              ? '${training.total}'
              : (training.ritmo?.toString() ?? ''),
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado correctamente')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar email: $e')),
        );
      }
    }

    void volverAlInicio() {
      // Limpia el estado del entrenamiento
      ref.read(trainingProvider.notifier).reset();
      // Navega al home
      context.go('/');
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
                    Text('💪 Fuerza efectiva: ${fmtPct(training.fuerza)} %'),
                    const SizedBox(height: 8),
                    Text('❤️ Pulsos efectivos: ${fmtPct(training.pulsos)} %'),
                    const SizedBox(height: 8),
                    if (training.total != null)
                      Text('🧠 Compresiones totales: ${training.total}')
                    else
                      Text('Ritmo: ${training.ritmo ?? '-'}'),
                  ],
                ),

                const SizedBox(height: 32),

                // Botón de enviar email
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
                      'Enviar reporte por email',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🏠 Botón para volver al inicio y resetear provider
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: volverAlInicio,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reiniciar entrenamiento',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
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
