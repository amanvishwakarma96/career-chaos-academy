import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_visual_settings_model.dart';

class GameVisualSettingsService {
  GameVisualSettingsService._();

  static final GameVisualSettingsService instance =
      GameVisualSettingsService._();

  static const String _qualityKey = 'career_chaos_game_visual_quality';

  final ValueNotifier<GameVisualQuality> quality =
      ValueNotifier<GameVisualQuality>(GameVisualQuality.balanced);

  GameVisualQuality get currentQuality => quality.value;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    quality.value = gameVisualQualityFromStorage(
      preferences.getString(_qualityKey),
    );
  }

  Future<void> setQuality(GameVisualQuality value) async {
    if (quality.value == value) {
      return;
    }
    quality.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_qualityKey, value.storageValue);
  }
}
