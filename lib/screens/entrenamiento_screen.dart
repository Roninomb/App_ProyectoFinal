import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_manager.dart';

// Providers que ya usabas para el resultado
import '../providers/user_provider.dart';
// Nuevo provider central de entrenamiento
import '../providers/training_provider.dart';

class EntrenamientoScreen extends ConsumerStatefulWidget {
  const EntrenamientoScreen({super.key});

  @override
  ConsumerState<EntrenamientoScreen> createState() =>
      _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends ConsumerState<EntrenamientoScreen> {
  final BleManager bleManager = BleManager();

  @override
  void initState() {
    super.initState();

    // Suscripción a los datos BLE
    bleManager.escucharDatos((data) {
      // 1) Actualiza el provider central
      ref.read(trainingProvider.notifier).updateFromBle(data);

      // 2) (Opcional) Sincroniza con los providers del ResultadoScreen
      final t = ref.read(trainingProvider);
      if (t.fuerza != null) {
        ref.read(fuerzaProvider.notifier).state = t.fuerza!;
      }
      if (t.pulsos != null) {
        ref.read(pulsosProvider.notifier).state = t.pulsos!;
      }
      if (t.ritmo != null) {
        ref.read(ritmoProvider.notifier).state = t.ritmo!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Datos recibidos!')),
        );
      }
    });
  }

  @override
  void dispose() {
    bleManager.cancelarEscucha();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final training = ref.watch(trainingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: Center(
        child: (training.raw == null)
            ? const _AnimatedTraining()
            : _TrainingValuesView(training: training),
      ),
    );
  }
}

class _TrainingValuesView extends StatelessWidget {
  final TrainingData training;
  const _TrainingValuesView({required this.training});

  @override
  Widget build(BuildContext context) {
    final fuerzaTxt = training.fuerza == null
        ? '—'
        : '${training.fuerza!.toStringAsFixed(1)} %';
    final pulsosTxt = training.pulsos == null ? '—' : '${training.pulsos} %';
    final ritmoTxt =
        training.ritmo == null ? '—' : (training.ritmo! ? 'Correcto' : 'Incorrecto');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('💪 Fuerza efectiva: $fuerzaTxt'),
        const SizedBox(height: 8),
        Text('❤️ Pulsos efectivos: $pulsosTxt'),
        const SizedBox(height: 8),
        Text('🕒 Ritmo: $ritmoTxt'),
        const SizedBox(height: 16),
        Text('RAW: ${training.raw}'),
      ],
    );
  }
}

// Animación simple de entrenamiento (círculo pulsante)
class _AnimatedTraining extends StatefulWidget {
  const _AnimatedTraining();

  @override
  State<_AnimatedTraining> createState() => _AnimatedTrainingState();
}

class _AnimatedTrainingState extends State<_AnimatedTraining>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.8, end: 1.1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.fitness_center, color: Colors.white, size: 40),
            ),
          ),
        );
      },
    );
  }
}
