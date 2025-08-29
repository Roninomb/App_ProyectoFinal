// lib/screens/entrenamiento_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/ble_provider.dart';
import '../providers/training_provider.dart';

class EntrenamientoScreen extends ConsumerStatefulWidget {
  const EntrenamientoScreen({super.key});

  @override
  ConsumerState<EntrenamientoScreen> createState() => _EntrenamientoScreenState();
}

class _EntrenamientoScreenState extends ConsumerState<EntrenamientoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final ProviderSubscription<BleState> _bleSub;

  bool _started = false;
  String? _error;

  bool _isFinalResult(String msg) {
    try {
      final obj = json.decode(msg);
      return obj is Map<String, dynamic> &&
          obj.containsKey('fuerza') &&
          obj.containsKey('pulsos') &&
          obj.containsKey('ritmo');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);

    // Escucha manual del provider para poder usarlo fuera de build().
    _bleSub = ref.listenManual<BleState>(bleProvider, (prev, next) {
      final msg = next.lastJson;
      if (msg == null || msg.isEmpty || prev?.lastJson == msg) return;

      // ⛔ Ignorar ACK y mensajes intermedios
      if (!_isFinalResult(msg)) return;

      try {
        final Map<String, dynamic> raw = json.decode(msg);
        final Map<String, String> data =
            raw.map((k, v) => MapEntry(k, '$v'));

        ref.read(trainingProvider.notifier).updateFromBle(data);

        if (!mounted) return;
        context.go('/resultado');
      } catch (_) {
        if (!mounted) return;
        setState(() => _error = 'Datos finales inválidos (no es JSON)');
      }
    });
  }

  @override
  void dispose() {
    _bleSub.close();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _onStartPressed() async {
    setState(() {
      _started = true;
      _error = null;
    });

    try {
      // Envía START (el provider ya manejará deduplicación/limpieza)
      await ref.read(bleProvider.notifier).startTrainingOnce();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _started = false;
        _error = 'No se pudo iniciar el entrenamiento';
      });
    }
  }

  Future<void> _onCancelPressed() async {
    try {
      await ref.read(bleProvider.notifier).abortAll();
    } finally {
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ble = ref.watch(bleProvider); // solo para mostrar estado

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Encabezado
                Column(
                  children: [
                    Text(
                      _started ? 'En progreso…' : 'Listo para comenzar',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _started
                            ? 'Realizá las compresiones según las indicaciones.\nAl finalizar, se procesarán los datos automáticamente.'
                            : 'Cuando estés listo, presioná “Empezar”.\nEl dispositivo BLE ya debería estar conectado.',
                        key: ValueKey(_started),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),

                // Animación “respiración” + indicador
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _pulse.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(alpha: 0.10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.35),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            _started
                                ? const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 3),
                                    ),
                                  )
                                : Icon(
                                    Icons.play_arrow_rounded,
                                    size: 48,
                                    color: theme.colorScheme.primary,
                                  ),
                            const SizedBox(height: 10),
                            Text(
                              _started ? 'Esperando datos…' : 'Listo',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$ble',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Botonera
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _started ? null : _onStartPressed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _started ? 'En progreso…' : 'Empezar',
                            key: ValueKey(_started),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _onCancelPressed,
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
