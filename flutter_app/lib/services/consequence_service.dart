import '../models/consequence_update_model.dart';
import '../models/outcome_model.dart';
import '../models/relationship_score_model.dart';
import '../models/scenario_model.dart';
import '../models/score_model.dart';

class ChapterAvailability {
  final bool isAvailable;
  final bool isBlocked;
  final List<String> reasons;

  const ChapterAvailability({
    required this.isAvailable,
    this.isBlocked = false,
    this.reasons = const <String>[],
  });
}

class ConsequenceService {
  ConsequenceService._();

  static final ConsequenceService instance = ConsequenceService._();

  ConsequenceUpdateModel applyOutcome({
    required Set<String> currentFlags,
    required OutcomeModel outcome,
  }) {
    return ConsequenceUpdateModel.fromOutcome(
      currentFlags: currentFlags,
      outcome: outcome,
    );
  }

  ChapterAvailability availabilityForChapter({
    required ScenarioModel chapter,
    required Set<String> activeFlags,
    required Set<String> completedChapterIds,
    ScoreModel roleScore = ScoreModel.zero,
    Set<String> unlockedCleanupMissionIds = const <String>{},
    Set<String> storyFlags = const <String>{},
    RelationshipScoreModel relationship = RelationshipScoreModel.zero,
  }) {
    final reasons = <String>[];

    final missingPrerequisites = chapter.prerequisites.where(
      (chapterId) => !completedChapterIds.contains(chapterId),
    );
    if (missingPrerequisites.isNotEmpty) {
      reasons.add('Complete prerequisite: ${missingPrerequisites.join(', ')}');
    }

    final blockingFlags = chapter.blockedByFlags.where(activeFlags.contains);
    if (blockingFlags.isNotEmpty) {
      reasons.add('Blocked by active issue: ${blockingFlags.join(', ')}');
    }

    final requiredFlags = chapter.consequenceFlags.where(
      (flag) => !activeFlags.contains(flag),
    );
    if (requiredFlags.isNotEmpty) {
      reasons.add('Requires consequence: ${requiredFlags.join(', ')}');
    }

    final missingStoryFlags = chapter.requiredStoryFlags.where(
      (flag) => !storyFlags.contains(flag),
    );
    if (missingStoryFlags.isNotEmpty) {
      reasons.add('Requires story state: ${missingStoryFlags.join(', ')}');
    }

    final blockedStoryFlags = chapter.blockedByStoryFlags.where(storyFlags.contains);
    if (blockedStoryFlags.isNotEmpty) {
      reasons.add('Blocked by story state: ${blockedStoryFlags.join(', ')}');
    }

    final requiredRelationship = chapter.requiredRelationshipMinimums;
    if (requiredRelationship != null && !relationship.meets(requiredRelationship)) {
      reasons.add('Relationship trust is not strong enough yet.');
    }

    if (chapter.isCleanupMission &&
        !unlockedCleanupMissionIds.contains(chapter.id) &&
        !completedChapterIds.contains(chapter.id)) {
      reasons.add('Cleanup mission is not unlocked yet.');
    }

    final requiredScore = chapter.requiredScoreMinimums;
    if (requiredScore != null && !_meetsScore(roleScore, requiredScore)) {
      reasons.add('Required score profile is not met yet.');
    }

    return ChapterAvailability(
      isAvailable: reasons.isEmpty,
      isBlocked: reasons.isNotEmpty,
      reasons: List<String>.unmodifiable(reasons),
    );
  }

  bool _meetsScore(ScoreModel actual, ScoreModel required) {
    return actual.skill >= required.skill &&
        actual.discipline >= required.discipline &&
        actual.ethics >= required.ethics &&
        actual.communication >= required.communication &&
        actual.chaos <= required.chaos;
  }
}
