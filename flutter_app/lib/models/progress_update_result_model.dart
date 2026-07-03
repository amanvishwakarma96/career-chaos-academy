import 'badge_model.dart';
import 'rank_model.dart';
import 'relationship_score_model.dart';
import 'reputation_model.dart';

class ProgressUpdateResultModel {
  final int xpGained;
  final int totalXp;
  final RankModel previousRank;
  final RankModel currentRank;
  final List<BadgeModel> newlyUnlockedBadges;
  final bool wasAlreadyCompleted;
  final List<String> flagsSet;
  final List<String> flagsCleared;
  final List<String> unlockedCleanupMissionIds;
  final ReputationModel reputationImpact;
  final String? roleEnding;
  final List<String> storyFlagsSet;
  final List<String> storyFlagsCleared;
  final RelationshipScoreModel relationshipImpact;
  final List<String> delayedConsequenceMessages;

  const ProgressUpdateResultModel({
    required this.xpGained,
    required this.totalXp,
    required this.previousRank,
    required this.currentRank,
    this.newlyUnlockedBadges = const <BadgeModel>[],
    this.wasAlreadyCompleted = false,
    this.flagsSet = const <String>[],
    this.flagsCleared = const <String>[],
    this.unlockedCleanupMissionIds = const <String>[],
    this.reputationImpact = ReputationModel.zero,
    this.roleEnding,
    this.storyFlagsSet = const <String>[],
    this.storyFlagsCleared = const <String>[],
    this.relationshipImpact = RelationshipScoreModel.zero,
    this.delayedConsequenceMessages = const <String>[],
  });

  bool get hasNewBadges => newlyUnlockedBadges.isNotEmpty;
  bool get didRankUp => previousRank.rank != currentRank.rank;
  bool get hasConsequences =>
      flagsSet.isNotEmpty ||
      flagsCleared.isNotEmpty ||
      unlockedCleanupMissionIds.isNotEmpty ||
      reputationImpact.total != 0 ||
      roleEnding != null ||
      storyFlagsSet.isNotEmpty ||
      storyFlagsCleared.isNotEmpty ||
      relationshipImpact.total != 0 ||
      delayedConsequenceMessages.isNotEmpty;
}
