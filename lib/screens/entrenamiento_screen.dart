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

    // Escucha BLE fuera de build() sin violar reglas de Riverpod.
    _bleSub = ref.listenManual<BleState>(bleProvider, (prev, next) {
      final msg = next.lastJson;
      if (msg == null || msg.isEmpty || prev?.lastJson == msg) return;
      if (!_isFinalResult(msg)) return; // ignorar ACK/ticks/otros

      try {
        final Map<String, dynamic> raw = json.decode(msg);
        final Map<String, String> data =
            raw.map((k, v) => MapEntry(k, '$v'));
        // Guarda en el provider de resultados (si ya lo usás en ResultadoScreen).
        ref.read(trainingProvider.notifier).updateFromBle(data);
      } catch (_) {
        // si viene malformado, no navegamos
        return;
      }

      if (!mounted) return;
      context.go('/resultado');
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
      // El provider limpia lastJson y deduplica START.
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
    final ble = ref.watch(bleProvider); // para mostrar estado

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
                            ? 'Realizá las compresiones. Al finalizar se procesan los datos automáticamente.'
                            : 'Cuando estés listo, presioná “Empezar”.',
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

                // Animación “respiración” + estado
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
                              ble.connected ? 'Bluetooth listo' : 'Conectando…',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            // ▼ DEBUG opcional: ver el último mensaje BLE recibido
                            // const SizedBox(height: 6),
                            // Text(
                            //   ref.watch(bleProvider).lastJson ?? '—',
                            //   style: theme.textTheme.labelSmall,
                            //   textAlign: TextAlign.center,
                            //   maxLines: 2,
                            //   overflow: TextOverflow.ellipsis,
                            // ),
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
