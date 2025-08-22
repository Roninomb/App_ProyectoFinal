import 'package:flutter/material.dart';
import '../ble/ble_manager.dart';

class EntrenamientoScreen extends StatefulWidget {
  const EntrenamientoScreen({super.key});

  @override
  State<EntrenamientoScreen> createState() => _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends State<EntrenamientoScreen> {
  final BleManager bleManager = BleManager(); // O pásalo desde la pantalla anterior
  Map<String, String>? datosRecibidos;

  @override
  void initState() {
    super.initState();
    bleManager.escucharDatos((data) {
      setState(() {
        datosRecibidos = data;
      });
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
      body: Center(
        child: datosRecibidos == null
            ? const Text('Esperando datos...')
            : Text('Datos: $datosRecibidos'),
      ),
    );
  }
}