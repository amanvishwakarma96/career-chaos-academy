import '../models/ending_rule_model.dart';
import '../models/relationship_score_model.dart';
import '../models/reputation_model.dart';
import '../models/role_progress_model.dart';
import '../models/score_model.dart';

class FinaleService {
  FinaleService._();

  static final FinaleService instance = FinaleService._();

  String calculateEnding({
    required RoleProgressModel progress,
    required ScoreModel roleScore,
    required ReputationModel reputation,
    required Set<String> activeFlags,
    required Set<String> completedCleanupMissionIds,
    Set<String> storyFlags = const <String>{},
    RelationshipScoreModel relationship = RelationshipScoreModel.zero,
    List<EndingRuleModel> endingRules = const <EndingRuleModel>[],
  }) {
    final customEnding = _firstMatchingEndingRule(
      endingRules: endingRules,
      roleScore: roleScore,
      activeFlags: activeFlags,
      storyFlags: storyFlags,
      relationship: relationship,
    );
    if (customEnding != null) {
      return customEnding;
    }

    final unresolvedRisk = activeFlags.isNotEmpty;
    final chaos = roleScore.chaos;
    final relationshipTotal = relationship.total;
    final professionalScore = roleScore.skill +
        roleScore.discipline +
        roleScore.ethics +
        roleScore.communication +
        reputation.total +
        relationshipTotal;

    if (storyFlags.contains('public_trust_broken') ||
        storyFlags.contains('unsafe_shortcut_normalized')) {
      return 'Reputation Recovery Required';
    }
    if (chaos >= 12 || reputation.safety <= -5 || reputation.trust <= -6) {
      return 'Unsafe Intern';
    }
    if (relationship.clientTrust <= -6 || relationship.teamTrust <= -6) {
      return 'Relationship Repair Track';
    }
    if (unresolvedRisk && completedCleanupMissionIds.isEmpty) {
      return 'Chaotic Learner';
    }
    if (professionalScore >= 65 && chaos <= 3 && !unresolvedRisk) {
      return 'Role Expert';
    }
    if (professionalScore >= 42 && chaos <= 7) {
      return 'Trusted Professional';
    }
    if (professionalScore >= 20) {
      return 'Reliable Junior';
    }
    return 'Chaotic Learner';
  }

  String? _firstMatchingEndingRule({
    required List<EndingRuleModel> endingRules,
    required ScoreModel roleScore,
    required Set<String> activeFlags,
    required Set<String> storyFlags,
    required RelationshipScoreModel relationship,
  }) {
    for (final rule in endingRules) {
      if (!rule.requiredStoryFlags.every(storyFlags.contains)) {
        continue;
      }
      if (rule.blockedByStoryFlags.any(storyFlags.contains)) {
        continue;
      }
      if (!rule.requiredConsequenceFlags.every(activeFlags.contains)) {
        continue;
      }
      if (rule.blockedByConsequenceFlags.any(activeFlags.contains)) {
        continue;
      }
      final requiredScore = rule.requiredScoreMinimums;
      if (requiredScore != null && !_meetsScore(roleScore, requiredScore)) {
        continue;
      }
      final requiredRelationship = rule.requiredRelationshipMinimums;
      if (requiredRelationship != null && !relationship.meets(requiredRelationship)) {
        continue;
      }
      return rule.title;
    }
    return null;
  }

  bool _meetsScore(ScoreModel actual, ScoreModel required) {
    return actual.skill >= required.skill &&
        actual.discipline >= required.discipline &&
        actual.ethics >= required.ethics &&
        actual.communication >= required.communication &&
        actual.chaos <= required.chaos;
  }
}
