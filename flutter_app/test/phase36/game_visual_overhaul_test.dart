import 'dart:convert';

import 'package:career_chaos_academy/games/bug_hunt_room_game.dart';
import 'package:career_chaos_academy/models/game_visual_settings_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 36 game visual overhaul', () {
    test('visual quality modes expose progressively larger effect budgets', () {
      expect(
        GameVisualQuality.performance.particleBudget,
        lessThan(GameVisualQuality.balanced.particleBudget),
      );
      expect(
        GameVisualQuality.balanced.particleBudget,
        lessThan(GameVisualQuality.cinematic.particleBudget),
      );
      expect(GameVisualQuality.performance.usesHeavyEffects, isFalse);
      expect(GameVisualQuality.cinematic.usesHeavyEffects, isTrue);
    });

    test('Bug Hunt vertical slice has enough interactive incident targets', () {
      final definition = BugHuntRoomGame.definition;
      final correctTargets =
          definition.targets.where((target) => target.isCorrect).length;

      expect(definition.targets.length, greaterThanOrEqualTo(5));
      expect(correctTargets, greaterThanOrEqualTo(definition.successThreshold));
      expect(definition.timeLimitSeconds, greaterThan(0));
    });

    test('game visual overhaul is enabled through the feature flag', () async {
      final raw = await rootBundle.loadString(
        'assets/config/feature_flags.json',
      );
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final flags = (json['flags'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final visualFlag = flags.firstWhere(
        (flag) => flag['key'] == 'game_visual_overhaul',
      );

      expect(visualFlag['enabled'], isTrue);
      expect(visualFlag['rolloutPercentage'], 100);
    });
  });
}
