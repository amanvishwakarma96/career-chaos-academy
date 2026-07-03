import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/future_scope/feature_flag_model.dart';

class FeatureFlagService {
  FeatureFlagService._();

  static final FeatureFlagService instance = FeatureFlagService._();

  final ValueNotifier<Map<String, FeatureFlagModel>> flags =
      ValueNotifier<Map<String, FeatureFlagModel>>(const <String, FeatureFlagModel>{});

  Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/config/feature_flags.json');
      final decoded = jsonDecode(raw);
      final items = decoded is Map<String, dynamic> ? decoded['flags'] : null;
      if (items is List) {
        final loaded = <String, FeatureFlagModel>{};
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final flag = FeatureFlagModel.fromJson(item);
            if (flag.key.isNotEmpty) loaded[flag.key] = flag;
          }
        }
        flags.value = Map<String, FeatureFlagModel>.unmodifiable(loaded);
      }
    } catch (_) {
      flags.value = _fallbackFlags;
    }
  }

  bool isEnabled(String key, {bool fallback = false}) {
    final flag = flags.value[key];
    return flag?.enabled ?? fallback;
  }

  Map<String, bool> snapshot() => flags.value.map(
        (key, value) => MapEntry(key, value.enabled),
      );

  static const Map<String, FeatureFlagModel> _fallbackFlags = <String, FeatureFlagModel>{
    'activity_hub': FeatureFlagModel(key: 'activity_hub', enabled: true),
    'flame_minigames': FeatureFlagModel(key: 'flame_minigames', enabled: true),
    'ai_scenario_lab': FeatureFlagModel(key: 'ai_scenario_lab', enabled: false),
    'premium_content': FeatureFlagModel(key: 'premium_content', enabled: false),
    'multiplayer_placeholder': FeatureFlagModel(key: 'multiplayer_placeholder', enabled: false),
    'team_simulation': FeatureFlagModel(key: 'team_simulation', enabled: true),
    'interview_mode': FeatureFlagModel(key: 'interview_mode', enabled: true),
    'certification_engine': FeatureFlagModel(key: 'certification_engine', enabled: true),
    'corporate_college_edition': FeatureFlagModel(key: 'corporate_college_edition', enabled: true),
    'ai_voice_conversation': FeatureFlagModel(key: 'ai_voice_conversation', enabled: true),
    'learning_analytics': FeatureFlagModel(key: 'learning_analytics', enabled: true),
    'monetization_system': FeatureFlagModel(key: 'monetization_system', enabled: true),
  };
}
