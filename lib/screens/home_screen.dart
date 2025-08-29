// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    // Prefill desde Riverpod (mantiene la lógica de estado centralizado)
    _nombreCtrl = TextEditingController(text: ref.read(nombreProvider));
    _emailCtrl  = TextEditingController(text: ref.read(emailProvider));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observa el estado para habilitar/deshabilitar el botón
    final nombre = ref.watch(nombreProvider);
    final email  = ref.watch(emailProvider);
    final camposValidos = nombre.trim().isNotEmpty && email.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FE),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NeoRCP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  color: Color(0xFF1C2E45),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Contenedor blanco
              Container(
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nombreCtrl,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) =>
                          ref.read(nombreProvider.notifier).state = value,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailCtrl,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) =>
                          ref.read(emailProvider.notifier).state = value,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: camposValidos
                            ? () {
                                
                                context.pushNamed('pretrain');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: camposValidos
                              ? const Color(0xFFF26464)
                              : Colors.grey[300],
                          foregroundColor:
                              camposValidos ? Colors.white : Colors.black45,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Comenzar entrenamiento'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
