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
          fuerza: fuerza,
          pulsos: pulsos,
          ritmo: ritmo,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📩 Reporte enviado correctamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al enviar email: $e')),
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(title: const Text('Resultado del entrenamiento')),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💪 Fuerza efectiva: ${fuerza.toStringAsFixed(1)} %'),
                    const SizedBox(height: 8),
                    Text('❤️ Pulsos efectivos: $pulsos %'),
                    const SizedBox(height: 8),
                    Text('🕒 Ritmo: ${ritmo ? 'Correcto' : 'Incorrecto'}'),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: enviarEmail,
                    child: const Text(
                      '📧 Enviar reporte por email',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
