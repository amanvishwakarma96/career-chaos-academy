import 'dart:convert';

import 'package:career_chaos_academy/core/asset_registry.dart';
import 'package:career_chaos_academy/widgets/developer_character_animation.dart';
import 'package:career_chaos_academy/widgets/developer_game_feel_frame.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const assets = <String, String>{
    'anim_developer_idle': 'assets/game/lottie/developer_idle.json',
    'anim_developer_walk': 'assets/game/lottie/developer_walk.json',
    'anim_developer_worried': 'assets/game/lottie/developer_worried.json',
    'anim_developer_office_environment':
        'assets/game/lottie/developer_office_environment.json',
    'anim_developer_lab_environment':
        'assets/game/lottie/developer_lab_environment.json',
  };

  test('Phase 36I authored Lottie assets are bundled and structurally valid',
      () async {
    for (final entry in assets.entries) {
      final raw = await rootBundle.loadString(entry.value);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['v'], isNotNull, reason: entry.key);
      expect(decoded['fr'], greaterThan(0), reason: entry.key);
      expect(decoded['op'], greaterThan(decoded['ip'] as num), reason: entry.key);
      expect(decoded['nm'], contains('Developer'), reason: entry.key);

      final layers = decoded['layers'] as List<dynamic>;
      expect(layers, isNotEmpty, reason: entry.key);
      expect(layers.length, greaterThanOrEqualTo(10), reason: entry.key);
    }
  });

  test('Developer walk asset contains real animated keyframes', () async {
    final raw = await rootBundle.loadString(
      'assets/game/lottie/developer_walk.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final layers = decoded['layers'] as List<dynamic>;

    final hasAnimatedTransform = layers.any((dynamic layer) {
      final layerMap = layer as Map<String, dynamic>;
      final transform = layerMap['ks'] as Map<String, dynamic>?;
      if (transform == null) {
        return false;
      }
      return transform.values.any((dynamic property) {
        return property is Map<String, dynamic> && property['a'] == 1;
      });
    });

    expect(hasAnimatedTransform, isTrue);
  });

  test('office and lab art have distinct authored scene vocabulary', () async {
    final office = await rootBundle.loadString(
      'assets/game/lottie/developer_office_environment.json',
    );
    final lab = await rootBundle.loadString(
      'assets/game/lottie/developer_lab_environment.json',
    );

    expect(office, contains('Release Rail'));
    expect(office, contains('Monitor'));
    expect(lab, contains('Incident Screen'));
    expect(lab, contains('Scan'));
    expect(office, isNot(equals(lab)));
  });

  test('AssetRegistry resolves every Phase 36I art asset with its own version',
      () {
    for (final entry in assets.entries) {
      expect(
        AssetRegistry.resolve(
          entry.key,
          type: GameAssetType.lottie,
          allowUnknownAssetPath: false,
        ),
        entry.value,
      );
      expect(
        AssetRegistry.versionFor(entry.key),
        AssetRegistry.developerArtVersion,
      );
    }
  });

  test('legacy Developer portrait references route to authored animation rig', () {
    expect(
      DeveloperCharacterAnimation.isDeveloperReference(
        'char_developer_neutral',
      ),
      isTrue,
    );
    expect(
      DeveloperCharacterAnimation.isDeveloperReference(
        'assets/game/characters/developer_focused.png',
      ),
      isTrue,
    );
    expect(
      DeveloperCharacterAnimation.isDeveloperReference('char_senior_calm'),
      isFalse,
    );
  });

  test('Developer emotion policy selects worried art only for pressure states',
      () {
    expect(
      DeveloperCharacterAnimation.modeForEmotion('worried'),
      DeveloperCharacterMode.worried,
    );
    expect(
      DeveloperCharacterAnimation.modeForEmotion('tense'),
      DeveloperCharacterMode.worried,
    );
    expect(
      DeveloperCharacterAnimation.modeForEmotion('focused'),
      DeveloperCharacterMode.idle,
    );
  });

  test('Developer simulation families receive distinct authored environments',
      () {
    expect(
      DeveloperGameFeelPolicy.environmentAssetKeyForTitle(
        'Release Pipeline',
      ),
      'anim_developer_office_environment',
    );
    expect(
      DeveloperGameFeelPolicy.environmentAssetKeyForTitle(
        'Live Production Incident',
      ),
      'anim_developer_lab_environment',
    );
  });
}
