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
      backgroundColor: const Color(0xFFEAF7FE), // fondo celeste claro
      appBar: AppBar(title: const Text('Resultado del entrenamiento')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '¡Buen trabajo, $nombre!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 24),
                Text('💪 Fuerza efectiva: ${fuerza.toStringAsFixed(1)} %'),
                Text('❤️ Pulsos efectivos: $pulsos %'),
                Text('🕒 Ritmo: ${ritmo ? 'Correcto' : 'Incorrecto'}'),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: enviarEmail,
                  icon: const Icon(Icons.email),
                  label: const Text('Enviar reporte por email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF26464),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
