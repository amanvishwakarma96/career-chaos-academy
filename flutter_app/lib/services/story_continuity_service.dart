import '../models/dialogue_line_model.dart';
import '../models/dialogue_scene_model.dart';
import '../models/relationship_score_model.dart';
import '../models/scenario_model.dart';

class StoryContinuityService {
  StoryContinuityService._();

  static final StoryContinuityService instance = StoryContinuityService._();

  bool isChapterVisible({
    required ScenarioModel chapter,
    required Set<String> storyFlags,
    RelationshipScoreModel relationship = RelationshipScoreModel.zero,
  }) {
    if (!_hasAll(storyFlags, chapter.requiredStoryFlags)) {
      return false;
    }
    if (_hasAny(storyFlags, chapter.blockedByStoryFlags)) {
      return false;
    }
    final requiredRelationship = chapter.requiredRelationshipMinimums;
    if (requiredRelationship != null && !relationship.meets(requiredRelationship)) {
      return false;
    }
    return true;
  }

  List<DialogueLineModel> visibleDialogues({
    required DialogueSceneModel scene,
    required Set<String> storyFlags,
    RelationshipScoreModel relationship = RelationshipScoreModel.zero,
  }) {
    return scene.dialogues.where((line) {
      if (!_hasAll(storyFlags, line.requiredStoryFlags)) {
        return false;
      }
      if (_hasAny(storyFlags, line.blockedByStoryFlags)) {
        return false;
      }
      final requiredRelationship = line.requiredRelationshipMinimums;
      if (requiredRelationship != null && !relationship.meets(requiredRelationship)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  bool _hasAll(Set<String> currentFlags, List<String> requiredFlags) {
    return requiredFlags.every(currentFlags.contains);
  }

  bool _hasAny(Set<String> currentFlags, List<String> blockedFlags) {
    return blockedFlags.any(currentFlags.contains);
  }
}
