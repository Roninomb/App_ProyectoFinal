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

  // Tiempo real (LIVE)
  int? _liveForceOk;     // 0/1
  int? _liveRhythmCat;   // 1 lento, 2 rápido, 3 correcto
  DateTime? _startAt;

  void _markStartIfNeeded() {
    _startAt ??= DateTime.now();
  }

  bool _isFinalResult(String msg) {
    try {
      final obj = json.decode(msg);
      if (obj is! Map<String, dynamic>) return false;
      final hasNew = obj.containsKey('fuerza') && obj.containsKey('pulsos') && obj.containsKey('total');
      final hasOld = obj.containsKey('fuerza') && obj.containsKey('pulsos') && obj.containsKey('ritmo');
      return hasNew || hasOld;
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

    // Listener BLE: LIVE(fuerza, ritmo) para tiempo real; JSON final para navegar
    _bleSub = ref.listenManual<BleState>(bleProvider, (prev, next) {
      final msg = next.lastJson;
      if (msg == null || msg.isEmpty || prev?.lastJson == msg) return;

      // 1) Tiempo real: "LIVE,<forceOk>,<rhythmCat>"
      if (msg.startsWith('LIVE,')) {
        final parts = msg.split(',');
        if (parts.length >= 3) {
          final f = int.tryParse(parts[1]); // 0/1
          final r = int.tryParse(parts[2]); // 1/2/3
          if (f != null && (f == 0 || f == 1) && r != null && r >= 1 && r <= 3) {
            setState(() {
              _markStartIfNeeded();
              _liveForceOk = f;
              _liveRhythmCat = r;
            });
          }
        }
        return; // no navegamos con LIVE
      }

      // 2) Resultado final (JSON)
      if (!_isFinalResult(msg)) return;

      try {
        final Map<String, dynamic> raw = json.decode(msg);
        final Map<String, String> data = raw.map((k, v) => MapEntry(k, '$v'));
        ref.read(trainingProvider.notifier).updateFromBle(data);
      } catch (_) {
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
      _liveForceOk = null;
      _liveRhythmCat = null;
      _startAt = null;
    });

    try {
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

  Widget _forceCard(BuildContext context) {
    final theme = Theme.of(context);
    final ok = _liveForceOk == 1;
    final Color base =
        _liveForceOk == null ? theme.colorScheme.surfaceContainerHighest : (ok ? Colors.green : Colors.red);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.withValues(alpha: 0.6), width: 2),
      ),
      child: Text(
        _liveForceOk == null
            ? 'Fuerza: —'
            : (ok ? 'Fuerza: CORRECTA' : 'Fuerza: INCORRECTA'),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: _liveForceOk == null ? theme.colorScheme.onSurface : Colors.black,
        ),
      ),
    );
  }

  Widget _rhythmCard(BuildContext context) {
    final theme = Theme.of(context);
    late Color base;
    late String text;
    switch (_liveRhythmCat) {
      case 1: base = Colors.orange; text = 'Ritmo: Muy lento'; break;
      case 2: base = Colors.red;    text = 'Ritmo: Muy rápido'; break;
      case 3: base = Colors.green;  text = 'Ritmo: Correcto';   break;
      default:
        base = theme.colorScheme.surfaceContainerHighest;
        text = 'Ritmo: —';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base.withValues(alpha: 0.6), width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: _liveRhythmCat == null ? theme.colorScheme.onSurface : Colors.black,
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = ref.watch(bleProvider.select((s) => s.connected));

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
                            ? 'Realizá las compresiones.'
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

                // “Respiración” + estado BLE
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
                                : const SizedBox(width: 28, height: 28),
                            const SizedBox(height: 10),
                            Text(
                              _started ? 'Esperando datos…' : '',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              connected ? 'Bluetooth listo' : 'Conectando…',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Tarjetas en tiempo real
                Column(
                  children: [
                    _forceCard(context),
                    const SizedBox(height: 12),
                    _rhythmCard(context),
                    const SizedBox(height: 6),
                    Text(
                      _startAt == null
                          ? 'Tiempo: 00:00'
                          : 'Tiempo: ${_fmt(DateTime.now().difference(_startAt!))}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
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
                              color: const Color(0xFFF26464),
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
