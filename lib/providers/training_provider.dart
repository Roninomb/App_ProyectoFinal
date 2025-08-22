import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modelo con los valores que usás para el reporte.
class TrainingData {
  final double? fuerza;           // %
  final int? pulsos;              // %
  final bool? ritmo;              // correcto / incorrecto
  final Map<String, String>? raw; // último paquete crudo parseado

  const TrainingData({
    this.fuerza,
    this.pulsos,
    this.ritmo,
    this.raw,
  });

  TrainingData copyWith({
    double? fuerza,
    int? pulsos,
    bool? ritmo,
    Map<String, String>? raw,
  }) {
    return TrainingData(
      fuerza: fuerza ?? this.fuerza,
      pulsos: pulsos ?? this.pulsos,
      ritmo: ritmo ?? this.ritmo,
      raw: raw ?? this.raw,
    );
  }
}

class TrainingDataNotifier extends StateNotifier<TrainingData> {
  TrainingDataNotifier() : super(const TrainingData());

  /// Actualiza el estado a partir del Map recibido por BLE.
  /// Soporta claves alternativas: fuerza|force|f, pulsos|p, ritmo|r.
  void updateFromBle(Map<String, String> data) {
    double? fuerza;
    int? pulsos;
    bool? ritmo;

    // Helpers locales (sin guion bajo para cumplir la regla del linter)
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

    // Buscar claves alternativas
    fuerza = parseDouble(
      data['fuerza'] ?? data['force'] ?? data['f'],
    );
    pulsos = parseInt(
      data['pulsos'] ?? data['pulsos_efectivos'] ?? data['p'],
    );
    ritmo = parseBool(
      data['ritmo'] ?? data['r'],
    );

    state = state.copyWith(
      fuerza: fuerza ?? state.fuerza,
      pulsos: pulsos ?? state.pulsos,
      ritmo: ritmo ?? state.ritmo,
      raw: data,
    );
  }

  void reset() => state = const TrainingData();
}

final trainingProvider =
    StateNotifierProvider<TrainingDataNotifier, TrainingData>(
  (ref) => TrainingDataNotifier(),
);
