import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EntrenamientoScreen extends StatefulWidget {
  final String nombre;
  final String email;

  const EntrenamientoScreen({
    super.key,
    required this.nombre,
    required this.email,
  });

  @override
  State<EntrenamientoScreen> createState() => _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends State<EntrenamientoScreen> {
  late Timer _timer;
  int _segundosRestantes = 10;

  final Random _random = Random();
  double _fuerzaTotal = 0;
  int _pulsosTotal = 0;
  int _mediciones = 0;
  int _ritmoCorrectoCount = 0;

  @override
  void initState() {
    super.initState();
    _iniciarEntrenamiento();
  }

  void _iniciarEntrenamiento() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _segundosRestantes--;
      });

      
      final nuevaFuerza = 30 + _random.nextDouble() * 70;
      final nuevosPulsos = 80 + _random.nextInt(40);
      final ritmoCorrecto = _random.nextBool();

      _fuerzaTotal += nuevaFuerza;
      _pulsosTotal += nuevosPulsos;
      _mediciones += 1;
      if (ritmoCorrecto) _ritmoCorrectoCount++;

      if (_segundosRestantes <= 0) {
        _timer.cancel();

        final promedioFuerza = _fuerzaTotal / _mediciones;
        final promedioPulsos = _pulsosTotal ~/ _mediciones;
        final ritmo = _ritmoCorrectoCount > _mediciones / 2;

        context.goNamed('resultado', extra: {
          'nombre': widget.nombre,
          'email': widget.email,
          'fuerza': promedioFuerza,
          'pulsos': promedioPulsos,
          'ritmo': ritmo,
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenando...')),
      body: Center(
        child: Text(
          'Tiempo restante: $_segundosRestantes s',
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
