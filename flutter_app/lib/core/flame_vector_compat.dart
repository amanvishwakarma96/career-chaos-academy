import 'dart:ui';

import 'package:flame/game.dart';

/// Small compatibility bridge for Flame pointer coordinates used by the
/// Developer incident arena.
extension FlameVector2OffsetCompat on Vector2 {
  Offset toOffset() => Offset(x, y);
}
