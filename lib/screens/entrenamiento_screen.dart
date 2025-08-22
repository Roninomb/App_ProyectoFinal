import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ble/ble_manager.dart';
import '../providers/training_provider.dart';

class EntrenamientoScreen extends ConsumerStatefulWidget {
  const EntrenamientoScreen({super.key});

  @override
  ConsumerState<EntrenamientoScreen> createState() =>
      _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends ConsumerState<EntrenamientoScreen> {
  final BleManager bleManager = BleManager();
  bool datosRecibidos = false;

  @override
  void initState() {
    super.initState();
    bleManager.escucharDatos((data) {
      ref.read(trainingProvider.notifier).updateFromBle(data);
      setState(() {
        datosRecibidos = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Datos recibidos!')),
        );
        // Navega automáticamente a la pantalla de resultados cuando llegan los datos
        Navigator.pushNamed(context, '/resultado');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: const Center(
        child: _AnimatedTraining(),
      ),
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
