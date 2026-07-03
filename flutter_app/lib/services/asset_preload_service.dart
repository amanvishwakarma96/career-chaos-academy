import 'package:flutter/widgets.dart';

import '../core/asset_registry.dart';
import '../core/character_registry.dart';
import '../models/scenario_model.dart';

class AssetPreloadService {
  const AssetPreloadService._();

  static Future<void> preloadScenarioAssets(
    BuildContext context,
    ScenarioModel scenario, {
    CharacterRegistry? characterRegistry,
  }) async {
    final references = collectScenarioAssetReferences(
      scenario,
      characterRegistry: characterRegistry,
    );
    for (final reference in references) {
      final resolved = AssetRegistry.resolve(reference);
      if (resolved == null) {
        continue;
      }
      try {
        if (AssetRegistry.isRemoteUrl(resolved)) {
          await precacheImage(NetworkImage(resolved), context);
        } else {
          await precacheImage(AssetImage(resolved), context);
        }
      } catch (_) {
        // Missing/invalid assets should never block gameplay. The runtime image
        // widget will show a visible placeholder instead.
      }
    }
  }

  static Set<String> collectScenarioAssetReferences(
    ScenarioModel scenario, {
    CharacterRegistry? characterRegistry,
  }) {
    final registry = characterRegistry ?? CharacterRegistry.empty;
    final references = <String>{};
    for (final scene in scenario.scenes) {
      _addIfPresent(references, scene.backgroundImage);
      _addIfPresent(references, scene.characterImage);
      final sceneCharacter = registry.findById(scene.characterId);
      _addIfPresent(
        references,
        sceneCharacter?.expressionFor(sceneCharacter.defaultEmotion),
      );
      for (final dialogue in scene.dialogues) {
        _addIfPresent(references, dialogue.characterImage);
        final character = registry.findForDialogue(
          characterId: dialogue.characterId ?? scene.characterId,
          speaker: dialogue.speaker,
        );
        _addIfPresent(references, character?.expressionFor(dialogue.emotion));
      }
    }
    return references;
  }

  static void _addIfPresent(Set<String> references, String? reference) {
    final value = reference?.trim();
    if (value != null && value.isNotEmpty) {
      references.add(value);
    }
  }
}
