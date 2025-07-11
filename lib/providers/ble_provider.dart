import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BLEStatus {
  idle,
  connecting,
  connected,
  failed,
}

final bleStatusProvider = StateProvider<BLEStatus>((ref) => BLEStatus.idle);
