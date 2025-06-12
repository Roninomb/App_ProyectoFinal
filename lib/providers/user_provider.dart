import 'package:flutter_riverpod/flutter_riverpod.dart';

final nombreProvider = StateProvider<String>((ref) => '');
final emailProvider = StateProvider<String>((ref) => '');
final fuerzaProvider = StateProvider<double>((ref) => 0.0);
final pulsosProvider = StateProvider<int>((ref) => 0);
final ritmoProvider = StateProvider<bool>((ref) => false);