import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modelo con los valores que usás para el reporte.
/// - `fuerza`: porcentaje 0..100
/// - `pulsos`: porcentaje 0..100
/// - `ritmo`: compat (bool) con firmware viejo
/// - `total`: compresiones totales (nuevo firmware; puede ser null)
/// - `raw`: último paquete crudo parseado (Map<String,String>)
class TrainingData {
  final double? fuerza;           // %
  final int? pulsos;              // %
  final bool? ritmo;              // correcto / incorrecto (compat)
  final int? total;               // compresiones totales
  final Map<String, String>? raw; // último paquete crudo parseado

  const TrainingData({
    this.fuerza,
    this.pulsos,
    this.ritmo,
    this.total,
    this.raw,
  });

  TrainingData copyWith({
    double? fuerza,
    int? pulsos,
    bool? ritmo,
    int? total,
    Map<String, String>? raw,
  }) {
    return TrainingData(
      fuerza: fuerza ?? this.fuerza,
      pulsos: pulsos ?? this.pulsos,
      ritmo: ritmo ?? this.ritmo,
      total: total ?? this.total,
      raw: raw ?? this.raw,
    );
  }
}

class TrainingDataNotifier extends StateNotifier<TrainingData> {
  TrainingDataNotifier() : super(const TrainingData());

  /// Actualiza el estado a partir del Map recibido por BLE.
  /// Claves alternativas aceptadas:
  ///   fuerza|force|f, pulsos|pulsos_efectivos|p, ritmo|r, total|total_compresiones|compresiones|t
  void updateFromBle(Map<String, String> data) {
    double? fuerza;
    int? pulsos;
    bool? ritmo;
    int? total;

    double? parseDouble(String? s) =>
        s == null ? null : double.tryParse(s.replaceAll(',', '.'));
    int? parseInt(String? s) => s == null ? null : int.tryParse(s);
    bool? parseBool(String? s) {
      if (s == null) return null;
      final v = s.trim().toLowerCase();
      if (v == '1' || v == 'true' || v == 'si' || v == 'sí' || v == 'ok') return true;
      if (v == '0' || v == 'false' || v == 'no') return false;
      return null;
    }

    fuerza = parseDouble(data['fuerza'] ?? data['force'] ?? data['f']);
    pulsos = parseInt(data['pulsos'] ?? data['pulsos_efectivos'] ?? data['p']);
    ritmo  = parseBool(data['ritmo'] ?? data['r']);
    total  = parseInt(
      data['total'] ?? data['total_compresiones'] ?? data['compresiones'] ?? data['t'],
    );

    // Compatibilidad: si no vino `pulsos` pero sí `ritmo` (bool), lo mapeamos
    if (pulsos == null && ritmo != null) {
      pulsos = ritmo ? 100 : 0;
    }

    state = state.copyWith(
      fuerza: fuerza ?? state.fuerza,
      pulsos: pulsos ?? state.pulsos,
      ritmo: ritmo ?? state.ritmo,
      total: total ?? state.total,
      raw: data,
    );
  }

  void reset() => state = const TrainingData();
}

final trainingProvider =
    StateNotifierProvider<TrainingDataNotifier, TrainingData>(
  (ref) => TrainingDataNotifier(),
);
