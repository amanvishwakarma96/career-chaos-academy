import 'package:flutter/foundation.dart';

import '../models/activity_model.dart';
import '../models/flame_mini_game_model.dart';
import '../models/career_coach/user_skill_profile_model.dart';
import '../models/mini_game_progress_model.dart';
import '../models/mini_game_result_model.dart';
import '../models/mentor/mentor_model.dart';
import '../models/outcome_model.dart';
import '../models/progress_snapshot_model.dart';
import '../models/progress_update_result_model.dart';
import '../models/rank_model.dart';
import '../models/relationship_score_model.dart';
import '../models/reputation_model.dart';
import '../models/role_progress_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../models/score_model.dart';
import '../models/skill_tree/skill_tree_model.dart';
import 'consequence_service.dart';
import 'finale_service.dart';
import 'gamification_service.dart';
import 'progress_api_service.dart';
import 'progress_storage.dart';
import 'release_monitoring_service.dart';
import 'relationship_service.dart';
import 'reputation_service.dart';
import 'score_api_service.dart';
import 'score_service.dart';
import 'skill_tree_service.dart';

class ProgressService {
  ProgressService._({ProgressStorage? storage})
      : _storage = storage ?? SharedPreferencesProgressStorage();

  static final ProgressService instance = ProgressService._();

  final ProgressStorage _storage;
  final ValueNotifier<Map<String, RoleProgressModel>> progressByRole =
      ValueNotifier<Map<String, RoleProgressModel>>(
    const <String, RoleProgressModel>{},
  );
  final ValueNotifier<Set<String>> badges = ValueNotifier<Set<String>>(
    const <String>{},
  );
  final ValueNotifier<int> totalXp = ValueNotifier<int>(0);
  final ValueNotifier<RankModel> careerRank = ValueNotifier<RankModel>(
    GamificationService.instance.rankForXp(0),
  );
  final ValueNotifier<Map<String, Set<String>>> activeFlagsByRole =
      ValueNotifier<Map<String, Set<String>>>(
    const <String, Set<String>>{},
  );
  final ValueNotifier<Map<String, Set<String>>> completedCleanupMissions =
      ValueNotifier<Map<String, Set<String>>>(
    const <String, Set<String>>{},
  );
  final ValueNotifier<Map<String, ReputationModel>> roleReputation =
      ValueNotifier<Map<String, ReputationModel>>(
    const <String, ReputationModel>{},
  );
  final ValueNotifier<Map<String, int>> miniGameAttempts =
      ValueNotifier<Map<String, int>>(
    const <String, int>{},
  );
  final ValueNotifier<Map<String, String>> roleEndings =
      ValueNotifier<Map<String, String>>(
    const <String, String>{},
  );
  final ValueNotifier<Map<String, Set<String>>> storyFlagsByRole =
      ValueNotifier<Map<String, Set<String>>>(
    const <String, Set<String>>{},
  );
  final ValueNotifier<Map<String, RelationshipScoreModel>> relationshipScoresByRole =
      ValueNotifier<Map<String, RelationshipScoreModel>>(
    const <String, RelationshipScoreModel>{},
  );
  final ValueNotifier<Map<String, List<String>>> delayedConsequencesByRole =
      ValueNotifier<Map<String, List<String>>>(
    const <String, List<String>>{},
  );
  final ValueNotifier<List<ActivityHistoryModel>> activityHistory =
      ValueNotifier<List<ActivityHistoryModel>>(
    const <ActivityHistoryModel>[],
  );
  final ValueNotifier<ActivityStreakModel> activityStreak =
      ValueNotifier<ActivityStreakModel>(ActivityStreakModel.zero);
  final ValueNotifier<int> activityXp = ValueNotifier<int>(0);
  final ValueNotifier<List<FlameMiniGameResultModel>> flameMiniGameHistory =
      ValueNotifier<List<FlameMiniGameResultModel>>(
    const <FlameMiniGameResultModel>[],
  );
  final ValueNotifier<int> flameMiniGameXp = ValueNotifier<int>(0);
  final ValueNotifier<ScoreModel> flameMiniGameScore =
      ValueNotifier<ScoreModel>(ScoreModel.zero);
  final ValueNotifier<MentorPreferenceModel> mentorPreference =
      ValueNotifier<MentorPreferenceModel>(MentorPreferenceModel.defaults);
  final ValueNotifier<CareerCoachStateModel> careerCoachState =
      ValueNotifier<CareerCoachStateModel>(CareerCoachStateModel.defaults);
  final ValueNotifier<Map<String, SkillTreeProgressModel>> skillTreeProgressByRole =
      ValueNotifier<Map<String, SkillTreeProgressModel>>(
    const <String, SkillTreeProgressModel>{},
  );

  Future<void> load() async {
    final localSnapshot = await _storage.loadProgress();
    final remoteSnapshot = await ProgressApiService.instance.loadProgress();
    final snapshot = _chooseLatestSnapshot(localSnapshot, remoteSnapshot);

    if (!identical(snapshot, localSnapshot)) {
      await _storage.saveProgress(snapshot);
    }

    _applySnapshot(snapshot);
  }

  void _applySnapshot(ProgressSnapshotModel snapshot) {
    progressByRole.value = Map<String, RoleProgressModel>.unmodifiable(
      snapshot.progressByRole,
    );
    badges.value = Set<String>.unmodifiable(snapshot.badges);
    totalXp.value = snapshot.totalXp;
    careerRank.value = GamificationService.instance.rankForXp(snapshot.totalXp);
    activeFlagsByRole.value = _deepSetMap(snapshot.activeFlagsByRole);
    completedCleanupMissions.value = _deepSetMap(
      snapshot.completedCleanupMissions,
    );
    roleReputation.value = Map<String, ReputationModel>.unmodifiable(
      snapshot.roleReputation,
    );
    miniGameAttempts.value = Map<String, int>.unmodifiable(
      snapshot.miniGameAttempts,
    );
    roleEndings.value = Map<String, String>.unmodifiable(snapshot.roleEndings);
    storyFlagsByRole.value = _deepSetMap(snapshot.storyFlagsByRole);
    relationshipScoresByRole.value = Map<String, RelationshipScoreModel>.unmodifiable(
      snapshot.relationshipScoresByRole,
    );
    delayedConsequencesByRole.value = _deepListMap(
      snapshot.delayedConsequencesByRole,
    );
    activityHistory.value = List<ActivityHistoryModel>.unmodifiable(snapshot.activityHistory);
    activityStreak.value = snapshot.activityStreak;
    activityXp.value = snapshot.activityXp;
    flameMiniGameHistory.value = List<FlameMiniGameResultModel>.unmodifiable(
      snapshot.flameMiniGameHistory,
    );
    flameMiniGameXp.value = snapshot.flameMiniGameXp;
    flameMiniGameScore.value = snapshot.flameMiniGameScore;
    mentorPreference.value = snapshot.mentorPreference;
    careerCoachState.value = snapshot.careerCoachState;
    skillTreeProgressByRole.value = Map<String, SkillTreeProgressModel>.unmodifiable(
      snapshot.skillTreeProgressByRole,
    );
    ScoreService.instance.setScore(snapshot.totalScore);
  }

  Map<String, List<String>> _deepListMap(Map<String, List<String>> source) {
    return Map<String, List<String>>.unmodifiable(
      source.map(
        (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
      ),
    );
  }

  Map<String, Set<String>> _deepSetMap(Map<String, Set<String>> source) {
    return Map<String, Set<String>>.unmodifiable(
      source.map(
        (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
      ),
    );
  }

  ProgressSnapshotModel _chooseLatestSnapshot(
    ProgressSnapshotModel localSnapshot,
    ProgressSnapshotModel? remoteSnapshot,
  ) {
    if (remoteSnapshot == null) {
      return localSnapshot;
    }

    final remoteHasProgress = remoteSnapshot.progressByRole.isNotEmpty ||
        remoteSnapshot.totalXp > 0 ||
        remoteSnapshot.badges.isNotEmpty ||
        remoteSnapshot.activeFlagsByRole.isNotEmpty ||
        remoteSnapshot.roleReputation.isNotEmpty ||
        remoteSnapshot.storyFlagsByRole.isNotEmpty ||
        remoteSnapshot.relationshipScoresByRole.isNotEmpty ||
        remoteSnapshot.activityHistory.isNotEmpty ||
        remoteSnapshot.activityXp > 0 ||
        remoteSnapshot.flameMiniGameHistory.isNotEmpty ||
        remoteSnapshot.flameMiniGameXp > 0 ||
        remoteSnapshot.mentorPreference != MentorPreferenceModel.defaults ||
        remoteSnapshot.careerCoachState.lastAdvice.isNotEmpty ||
        remoteSnapshot.careerCoachState.skillProfile.topStrengths.isNotEmpty ||
        remoteSnapshot.skillTreeProgressByRole.isNotEmpty;
    if (!remoteHasProgress) {
      return localSnapshot;
    }

    if (remoteSnapshot.totalXp >= localSnapshot.totalXp) {
      return remoteSnapshot;
    }

    return localSnapshot;
  }

  RoleProgressModel progressFor(String roleId) {
    return progressByRole.value[roleId] ?? RoleProgressModel(roleId: roleId);
  }

  Set<String> activeFlagsFor(String roleId) {
    return activeFlagsByRole.value[roleId] ?? const <String>{};
  }

  Set<String> storyFlagsFor(String roleId) {
    return storyFlagsByRole.value[roleId] ?? const <String>{};
  }

  RelationshipScoreModel relationshipFor(String roleId) {
    return relationshipScoresByRole.value[roleId] ?? RelationshipScoreModel.zero;
  }

  List<String> delayedConsequencesFor(String roleId) {
    return delayedConsequencesByRole.value[roleId] ?? const <String>[];
  }

  Set<String> completedCleanupMissionsFor(String roleId) {
    return completedCleanupMissions.value[roleId] ?? const <String>{};
  }

  Set<String> unlockedCleanupMissionIdsFor(String roleId) {
    final flags = activeFlagsFor(roleId);
    final progress = progressFor(roleId);
    final completed = completedCleanupMissionsFor(roleId);
    return <String>{
      ...progress.completedChapterIds.where((id) => id.contains('cleanup')),
      ...completed,
      ...flags.where((flag) => flag.endsWith('_cleanup_unlocked')),
    };
  }

  ReputationModel reputationFor(String roleId) {
    return roleReputation.value[roleId] ?? ReputationModel.zero;
  }

  SkillTreeProgressModel skillTreeProgressFor(String roleId) {
    return skillTreeProgressByRole.value[roleId] ??
        SkillTreeProgressModel(roleId: roleId);
  }


  ProgressSnapshotModel currentSnapshot() {
    return ProgressSnapshotModel(
      progressByRole: progressByRole.value,
      totalScore: ScoreService.instance.score.value,
      totalXp: totalXp.value,
      badges: badges.value,
      activeFlagsByRole: activeFlagsByRole.value,
      completedCleanupMissions: completedCleanupMissions.value,
      roleReputation: roleReputation.value,
      miniGameAttempts: miniGameAttempts.value,
      roleEndings: roleEndings.value,
      storyFlagsByRole: storyFlagsByRole.value,
      relationshipScoresByRole: relationshipScoresByRole.value,
      delayedConsequencesByRole: delayedConsequencesByRole.value,
      activityHistory: activityHistory.value,
      activityStreak: activityStreak.value,
      activityXp: activityXp.value,
      flameMiniGameHistory: flameMiniGameHistory.value,
      flameMiniGameXp: flameMiniGameXp.value,
      flameMiniGameScore: flameMiniGameScore.value,
      mentorPreference: mentorPreference.value,
      careerCoachState: careerCoachState.value,
      skillTreeProgressByRole: skillTreeProgressByRole.value,
    );
  }

  String? endingFor(String roleId) {
    return roleEndings.value[roleId];
  }

  bool isChapterUnlocked({required String roleId, required int chapterIndex}) {
    return progressFor(roleId).isChapterUnlocked(chapterIndex);
  }

  bool isChapterCompleted({required String roleId, required String chapterId}) {
    return progressFor(roleId).isChapterCompleted(chapterId);
  }

  MiniGameProgressModel? miniGameProgressFor({
    required String roleId,
    required String miniGameId,
  }) {
    return progressFor(roleId).miniGameResults[miniGameId];
  }

  bool isMiniGameCompleted({
    required String roleId,
    required String miniGameId,
  }) {
    return progressFor(roleId).isMiniGameCompleted(miniGameId);
  }

  ChapterProgressState chapterState({
    required String roleId,
    required int chapterIndex,
    required String chapterId,
  }) {
    return progressFor(roleId).chapterState(chapterIndex, chapterId);
  }

  double progressPercent(RoleScenarioModel roleScenario) {
    return progressFor(roleScenario.role.id).progressPercent(
      roleScenario.playableChapterCount,
    );
  }

  Future<void> recordMiniGameResult({
    required RoleScenarioModel roleScenario,
    required ScenarioModel chapter,
    required MiniGameResultModel result,
  }) async {
    final roleId = roleScenario.role.id;
    final currentProgress = progressFor(roleId);

    if (currentProgress.isMiniGameCompleted(result.miniGameId)) {
      return;
    }

    var updatedProgress = currentProgress.recordMiniGameResult(
      chapterId: chapter.id,
      result: result,
    );

    final attemptsMap = Map<String, int>.from(miniGameAttempts.value);
    attemptsMap[result.miniGameId] = (attemptsMap[result.miniGameId] ?? 0) + 1;

    final flagsMap = _mutableSetMap(activeFlagsByRole.value);
    final cleanupMap = _mutableSetMap(completedCleanupMissions.value);
    final reputationMap = Map<String, ReputationModel>.from(roleReputation.value);
    final storyFlagsMap = _mutableSetMap(storyFlagsByRole.value);
    final relationshipMap = Map<String, RelationshipScoreModel>.from(
      relationshipScoresByRole.value,
    );
    final delayedMap = _mutableListMap(delayedConsequencesByRole.value);
    var skillTreeProgressMap = Map<String, SkillTreeProgressModel>.from(
      skillTreeProgressByRole.value,
    );

    final miniGame = chapter.miniGame;
    if (miniGame != null) {
      final consequence = result.isSuccess
          ? miniGame.successConsequence
          : miniGame.failureConsequence;
      final currentFlags = flagsMap[roleId] ?? <String>{};
      final update = ConsequenceService.instance.applyOutcome(
        currentFlags: currentFlags,
        outcome: consequence,
      );
      flagsMap[roleId] = Set<String>.from(update.activeFlags);
      if (update.unlockedCleanupMissionIds.isNotEmpty) {
        flagsMap[roleId]!.addAll(
          update.unlockedCleanupMissionIds.map((id) => '${id}_cleanup_unlocked'),
        );
      }
      reputationMap[roleId] = ReputationService.instance.applyImpact(
        current: reputationMap[roleId] ?? ReputationModel.zero,
        impact: consequence.reputationImpact,
      );
      storyFlagsMap.putIfAbsent(roleId, () => <String>{}).addAll(consequence.setStoryFlags);
      storyFlagsMap[roleId]!.removeAll(consequence.clearStoryFlags);
      relationshipMap[roleId] = RelationshipService.instance.applyImpact(
        current: relationshipMap[roleId] ?? RelationshipScoreModel.zero,
        impact: consequence.relationshipImpact,
      );
      if (consequence.delayedConsequenceMessages.isNotEmpty) {
        delayedMap.putIfAbsent(roleId, () => <String>[]).addAll(
              consequence.delayedConsequenceMessages,
            );
      }
      if (chapter.isCleanupMission && result.isSuccess) {
        cleanupMap.putIfAbsent(roleId, () => <String>{}).add(chapter.id);
      }
      skillTreeProgressMap = await SkillTreeService.instance.awardMiniGameProgress(
        current: skillTreeProgressMap,
        roleScenario: roleScenario,
        chapter: chapter,
        miniGame: miniGame,
        isSuccess: result.isSuccess,
      );
    }

    final updatedMap = Map<String, RoleProgressModel>.from(progressByRole.value)
      ..[roleId] = updatedProgress;
    final updatedTotalScore = ProgressSnapshotModel.calculateTotalScore(
      updatedMap,
    ).add(flameMiniGameScore.value);
    final updatedTotalXp = ProgressSnapshotModel.calculateTotalXp(updatedMap) +
        activityXp.value +
        flameMiniGameXp.value;

    progressByRole.value = Map<String, RoleProgressModel>.unmodifiable(
      updatedMap,
    );
    totalXp.value = updatedTotalXp;
    activeFlagsByRole.value = _deepSetMap(flagsMap);
    completedCleanupMissions.value = _deepSetMap(cleanupMap);
    roleReputation.value = Map<String, ReputationModel>.unmodifiable(
      reputationMap,
    );
    miniGameAttempts.value = Map<String, int>.unmodifiable(attemptsMap);
    storyFlagsByRole.value = _deepSetMap(storyFlagsMap);
    relationshipScoresByRole.value = Map<String, RelationshipScoreModel>.unmodifiable(
      relationshipMap,
    );
    delayedConsequencesByRole.value = _deepListMap(delayedMap);
    skillTreeProgressByRole.value = Map<String, SkillTreeProgressModel>.unmodifiable(
      skillTreeProgressMap,
    );
    ScoreService.instance.setScore(updatedTotalScore);
    final currentBadges = Set<String>.from(badges.value);

    await _saveSnapshot(
      progressByRole: updatedMap,
      totalScore: updatedTotalScore,
      totalXp: updatedTotalXp,
      badges: currentBadges,
      activeFlagsByRole: flagsMap,
      completedCleanupMissions: cleanupMap,
      roleReputation: reputationMap,
      miniGameAttempts: attemptsMap,
      roleEndings: roleEndings.value,
      storyFlagsByRole: storyFlagsMap,
      relationshipScoresByRole: relationshipMap,
      delayedConsequencesByRole: delayedMap,
      activityHistory: activityHistory.value,
      activityStreak: activityStreak.value,
      activityXp: activityXp.value,
      skillTreeProgressByRole: skillTreeProgressMap,
    );
    await ReleaseMonitoringService.instance.logMiniGameCompleted(
      roleId: roleId,
      chapterId: chapter.id,
      miniGameId: result.miniGameId,
      passed: result.isSuccess,
      scoreImpact: result.scoreImpact.total,
    );
    await ScoreApiService.instance.saveScore(
      roleId: roleId,
      chapterId: chapter.id,
      score: result.scoreImpact,
    );
  }

  Future<ProgressUpdateResultModel> completeChapter({
    required RoleScenarioModel roleScenario,
    required ScenarioModel chapter,
    required ScoreModel scoreImpact,
    OutcomeModel? outcome,
  }) async {
    final roleId = roleScenario.role.id;
    final currentProgress = progressFor(roleId);
    final alreadyCompleted = currentProgress.isChapterCompleted(chapter.id);
    final xpGained = alreadyCompleted
        ? 0
        : GamificationService.instance.calculateXp(scoreImpact);
    final previousRank = careerRank.value;
    final previousBadges = Set<String>.from(badges.value);

    final playableChapters = roleScenario.chapters
        .where((item) => !item.isCleanupMission)
        .toList(growable: false);
    final updatedProgress = currentProgress.completeChapter(
      chapters: playableChapters,
      completedChapter: chapter,
      scoreImpact: scoreImpact,
      xpGained: xpGained,
    );

    final updatedMap = Map<String, RoleProgressModel>.from(progressByRole.value)
      ..[roleId] = updatedProgress;
    final updatedTotalScore = ProgressSnapshotModel.calculateTotalScore(
      updatedMap,
    ).add(flameMiniGameScore.value);
    final updatedTotalXp = ProgressSnapshotModel.calculateTotalXp(updatedMap) +
        activityXp.value +
        flameMiniGameXp.value;

    final flagsMap = _mutableSetMap(activeFlagsByRole.value);
    final cleanupMap = _mutableSetMap(completedCleanupMissions.value);
    final reputationMap = Map<String, ReputationModel>.from(roleReputation.value);
    final endingsMap = Map<String, String>.from(roleEndings.value);
    final storyFlagsMap = _mutableSetMap(storyFlagsByRole.value);
    final relationshipMap = Map<String, RelationshipScoreModel>.from(
      relationshipScoresByRole.value,
    );
    final delayedMap = _mutableListMap(delayedConsequencesByRole.value);
    var flagsSet = const <String>[];
    var flagsCleared = const <String>[];
    var cleanupUnlocked = const <String>[];
    var reputationImpact = ReputationModel.zero;
    var storyFlagsSet = const <String>[];
    var storyFlagsCleared = const <String>[];
    var relationshipImpact = RelationshipScoreModel.zero;
    var delayedMessages = const <String>[];
    var chapterSkillTreeProgressMap = Map<String, SkillTreeProgressModel>.from(
      skillTreeProgressByRole.value,
    );

    if (!alreadyCompleted && outcome != null) {
      final currentFlags = flagsMap[roleId] ?? <String>{};
      final consequence = ConsequenceService.instance.applyOutcome(
        currentFlags: currentFlags,
        outcome: outcome,
      );
      flagsMap[roleId] = Set<String>.from(consequence.activeFlags);
      if (consequence.unlockedCleanupMissionIds.isNotEmpty) {
        flagsMap[roleId]!.addAll(
          consequence.unlockedCleanupMissionIds.map(
            (id) => '${id}_cleanup_unlocked',
          ),
        );
      }
      flagsSet = consequence.flagsSet.toList(growable: false);
      flagsCleared = consequence.flagsCleared.toList(growable: false);
      cleanupUnlocked = consequence.unlockedCleanupMissionIds.toList(
        growable: false,
      );
      reputationImpact = outcome.reputationImpact;
      reputationMap[roleId] = ReputationService.instance.applyImpact(
        current: reputationMap[roleId] ?? ReputationModel.zero,
        impact: reputationImpact,
      );
      storyFlagsMap.putIfAbsent(roleId, () => <String>{}).addAll(outcome.setStoryFlags);
      storyFlagsMap[roleId]!.removeAll(outcome.clearStoryFlags);
      storyFlagsSet = outcome.setStoryFlags.toList(growable: false);
      storyFlagsCleared = outcome.clearStoryFlags.toList(growable: false);
      relationshipImpact = outcome.relationshipImpact;
      relationshipMap[roleId] = RelationshipService.instance.applyImpact(
        current: relationshipMap[roleId] ?? RelationshipScoreModel.zero,
        impact: relationshipImpact,
      );
      delayedMessages = outcome.delayedConsequenceMessages.toList(growable: false);
      if (delayedMessages.isNotEmpty) {
        delayedMap.putIfAbsent(roleId, () => <String>[]).addAll(delayedMessages);
      }
    }

    if (chapter.isCleanupMission && !alreadyCompleted) {
      cleanupMap.putIfAbsent(roleId, () => <String>{}).add(chapter.id);
      for (final flag in chapter.consequenceFlags) {
        flagsMap[roleId]?.remove(flag);
      }
    }

    if (chapter.isFinale && !alreadyCompleted) {
      endingsMap[roleId] = FinaleService.instance.calculateEnding(
        progress: updatedMap[roleId]!,
        roleScore: updatedMap[roleId]!.roleScore,
        reputation: reputationMap[roleId] ?? ReputationModel.zero,
        activeFlags: flagsMap[roleId] ?? const <String>{},
        completedCleanupMissionIds: cleanupMap[roleId] ?? const <String>{},
        storyFlags: storyFlagsMap[roleId] ?? const <String>{},
        relationship: relationshipMap[roleId] ?? RelationshipScoreModel.zero,
        endingRules: chapter.endingRules,
      );
    }

    if (!alreadyCompleted) {
      chapterSkillTreeProgressMap = await SkillTreeService.instance.awardChapterProgress(
        current: chapterSkillTreeProgressMap,
        roleScenario: roleScenario,
        chapter: chapter,
      );
    }

    final badgeEvaluation =
        GamificationService.instance.evaluateBadgesAfterCompletion(
      roleScenario: roleScenario,
      progressByRole: updatedMap,
      totalScore: updatedTotalScore,
      totalXp: updatedTotalXp,
      previouslyUnlockedBadgeIds: previousBadges,
    );

    if (badgeEvaluation.currentRoleBadgeIds.isNotEmpty) {
      updatedMap[roleId] = updatedProgress.copyWith(
        badges: <String>{
          ...updatedProgress.badges,
          ...badgeEvaluation.currentRoleBadgeIds,
        },
      );
    }

    final updatedRank = GamificationService.instance.rankForXp(updatedTotalXp);

    progressByRole.value = Map<String, RoleProgressModel>.unmodifiable(
      updatedMap,
    );
    badges.value = Set<String>.unmodifiable(
      badgeEvaluation.allUnlockedBadgeIds,
    );
    totalXp.value = updatedTotalXp;
    careerRank.value = updatedRank;
    activeFlagsByRole.value = _deepSetMap(flagsMap);
    completedCleanupMissions.value = _deepSetMap(cleanupMap);
    roleReputation.value = Map<String, ReputationModel>.unmodifiable(
      reputationMap,
    );
    roleEndings.value = Map<String, String>.unmodifiable(endingsMap);
    storyFlagsByRole.value = _deepSetMap(storyFlagsMap);
    relationshipScoresByRole.value = Map<String, RelationshipScoreModel>.unmodifiable(
      relationshipMap,
    );
    delayedConsequencesByRole.value = _deepListMap(delayedMap);
    skillTreeProgressByRole.value = Map<String, SkillTreeProgressModel>.unmodifiable(
      chapterSkillTreeProgressMap,
    );
    ScoreService.instance.setScore(updatedTotalScore);

    await _saveSnapshot(
      progressByRole: updatedMap,
      totalScore: updatedTotalScore,
      totalXp: updatedTotalXp,
      badges: badgeEvaluation.allUnlockedBadgeIds,
      activeFlagsByRole: flagsMap,
      completedCleanupMissions: cleanupMap,
      roleReputation: reputationMap,
      miniGameAttempts: miniGameAttempts.value,
      roleEndings: endingsMap,
      storyFlagsByRole: storyFlagsMap,
      relationshipScoresByRole: relationshipMap,
      delayedConsequencesByRole: delayedMap,
      activityHistory: activityHistory.value,
      activityStreak: activityStreak.value,
      activityXp: activityXp.value,
      skillTreeProgressByRole: chapterSkillTreeProgressMap,
    );

    if (!alreadyCompleted) {
      await ReleaseMonitoringService.instance.logChapterCompleted(
        roleId: roleId,
        chapterId: chapter.id,
        xpGained: xpGained,
        totalXp: updatedTotalXp,
        totalScore: updatedTotalScore.total,
      );
      await ScoreApiService.instance.saveScore(
        roleId: roleId,
        chapterId: chapter.id,
        score: scoreImpact,
        xp: xpGained,
      );
    }

    return ProgressUpdateResultModel(
      xpGained: xpGained,
      totalXp: updatedTotalXp,
      previousRank: previousRank,
      currentRank: updatedRank,
      newlyUnlockedBadges: badgeEvaluation.newlyUnlockedBadges,
      wasAlreadyCompleted: alreadyCompleted,
      flagsSet: flagsSet,
      flagsCleared: flagsCleared,
      unlockedCleanupMissionIds: cleanupUnlocked,
      reputationImpact: reputationImpact,
      roleEnding: endingsMap[roleId],
      storyFlagsSet: storyFlagsSet,
      storyFlagsCleared: storyFlagsCleared,
      relationshipImpact: relationshipImpact,
      delayedConsequenceMessages: delayedMessages,
    );
  }

  Future<ActivityCompletionResultModel> recordActivityResult({
    required ActivityModel activity,
    required bool isSuccess,
    required int score,
    required int xpEarned,
    required String feedback,
  }) async {
    final completedAt = DateTime.now();
    final nextStreak = isSuccess
        ? activityStreak.value.recordSuccess(completedAt)
        : activityStreak.value;
    final history = ActivityHistoryModel(
      activityId: activity.id,
      activityType: activity.type,
      title: activity.title,
      completedAt: completedAt,
      isSuccess: isSuccess,
      score: score,
      xpEarned: xpEarned,
      streakAfter: nextStreak.currentStreak,
      feedback: feedback,
    );

    final nextHistory = <ActivityHistoryModel>[
      history,
      ...activityHistory.value,
    ].take(100).toList(growable: false);
    final nextActivityXp = activityXp.value + xpEarned;
    final nextBadges = Set<String>.from(badges.value);
    if (isSuccess && activity.rewardBadgeId.isNotEmpty) {
      nextBadges.add(activity.rewardBadgeId);
    }
    final nextTotalXp = ProgressSnapshotModel.calculateTotalXp(progressByRole.value) +
        nextActivityXp +
        flameMiniGameXp.value;

    activityHistory.value = List<ActivityHistoryModel>.unmodifiable(nextHistory);
    activityStreak.value = nextStreak;
    activityXp.value = nextActivityXp;
    badges.value = Set<String>.unmodifiable(nextBadges);
    totalXp.value = nextTotalXp;
    careerRank.value = GamificationService.instance.rankForXp(nextTotalXp);

    await _saveSnapshot(
      progressByRole: progressByRole.value,
      totalScore: ScoreService.instance.score.value,
      totalXp: nextTotalXp,
      badges: nextBadges,
      activeFlagsByRole: activeFlagsByRole.value,
      completedCleanupMissions: completedCleanupMissions.value,
      roleReputation: roleReputation.value,
      miniGameAttempts: miniGameAttempts.value,
      roleEndings: roleEndings.value,
      storyFlagsByRole: storyFlagsByRole.value,
      relationshipScoresByRole: relationshipScoresByRole.value,
      delayedConsequencesByRole: delayedConsequencesByRole.value,
      activityHistory: nextHistory,
      activityStreak: nextStreak,
      activityXp: nextActivityXp,
    );

    return ActivityCompletionResultModel(
      history: history,
      streak: nextStreak,
      totalXp: nextTotalXp,
    );
  }


  Future<void> recordFlameMiniGameResult(FlameMiniGameResultModel result) async {
    final nextHistory = <FlameMiniGameResultModel>[
      result,
      ...flameMiniGameHistory.value,
    ].take(100).toList(growable: false);
    final nextFlameXp = flameMiniGameXp.value + result.xpEarned;
    final nextFlameScore = flameMiniGameScore.value.add(result.scoreImpact);
    final nextTotalScore = ProgressSnapshotModel.calculateTotalScore(
      progressByRole.value,
    ).add(nextFlameScore);
    final nextTotalXp = ProgressSnapshotModel.calculateTotalXp(progressByRole.value) +
        activityXp.value +
        nextFlameXp;

    flameMiniGameHistory.value = List<FlameMiniGameResultModel>.unmodifiable(
      nextHistory,
    );
    flameMiniGameXp.value = nextFlameXp;
    flameMiniGameScore.value = nextFlameScore;
    totalXp.value = nextTotalXp;
    careerRank.value = GamificationService.instance.rankForXp(nextTotalXp);
    ScoreService.instance.setScore(nextTotalScore);

    await _saveSnapshot(
      progressByRole: progressByRole.value,
      totalScore: nextTotalScore,
      totalXp: nextTotalXp,
      badges: badges.value,
      activeFlagsByRole: activeFlagsByRole.value,
      completedCleanupMissions: completedCleanupMissions.value,
      roleReputation: roleReputation.value,
      miniGameAttempts: miniGameAttempts.value,
      roleEndings: roleEndings.value,
      storyFlagsByRole: storyFlagsByRole.value,
      relationshipScoresByRole: relationshipScoresByRole.value,
      delayedConsequencesByRole: delayedConsequencesByRole.value,
      activityHistory: activityHistory.value,
      activityStreak: activityStreak.value,
      activityXp: activityXp.value,
      flameMiniGameHistory: nextHistory,
      flameMiniGameXp: nextFlameXp,
      flameMiniGameScore: nextFlameScore,
    );
  }


  Future<void> updateMentorPreference(MentorPreferenceModel preference) async {
    mentorPreference.value = preference;
    await _saveSnapshot(
      progressByRole: progressByRole.value,
      totalScore: ScoreService.instance.score.value,
      totalXp: totalXp.value,
      badges: badges.value,
      activeFlagsByRole: activeFlagsByRole.value,
      completedCleanupMissions: completedCleanupMissions.value,
      roleReputation: roleReputation.value,
      miniGameAttempts: miniGameAttempts.value,
      roleEndings: roleEndings.value,
      storyFlagsByRole: storyFlagsByRole.value,
      relationshipScoresByRole: relationshipScoresByRole.value,
      delayedConsequencesByRole: delayedConsequencesByRole.value,
      activityHistory: activityHistory.value,
      activityStreak: activityStreak.value,
      activityXp: activityXp.value,
      flameMiniGameHistory: flameMiniGameHistory.value,
      flameMiniGameXp: flameMiniGameXp.value,
      flameMiniGameScore: flameMiniGameScore.value,
      mentorPreference: preference,
    );
  }


  Future<void> updateCareerCoachState(CareerCoachStateModel state) async {
    careerCoachState.value = state;
    await _saveSnapshot(
      progressByRole: progressByRole.value,
      totalScore: ScoreService.instance.score.value,
      totalXp: totalXp.value,
      badges: badges.value,
      activeFlagsByRole: activeFlagsByRole.value,
      completedCleanupMissions: completedCleanupMissions.value,
      roleReputation: roleReputation.value,
      miniGameAttempts: miniGameAttempts.value,
      roleEndings: roleEndings.value,
      storyFlagsByRole: storyFlagsByRole.value,
      relationshipScoresByRole: relationshipScoresByRole.value,
      delayedConsequencesByRole: delayedConsequencesByRole.value,
      activityHistory: activityHistory.value,
      activityStreak: activityStreak.value,
      activityXp: activityXp.value,
      flameMiniGameHistory: flameMiniGameHistory.value,
      flameMiniGameXp: flameMiniGameXp.value,
      flameMiniGameScore: flameMiniGameScore.value,
      mentorPreference: mentorPreference.value,
      careerCoachState: state,
    );
  }

  Future<void> reset() async {
    progressByRole.value = const <String, RoleProgressModel>{};
    badges.value = const <String>{};
    totalXp.value = 0;
    careerRank.value = GamificationService.instance.rankForXp(0);
    activeFlagsByRole.value = const <String, Set<String>>{};
    completedCleanupMissions.value = const <String, Set<String>>{};
    roleReputation.value = const <String, ReputationModel>{};
    miniGameAttempts.value = const <String, int>{};
    roleEndings.value = const <String, String>{};
    storyFlagsByRole.value = const <String, Set<String>>{};
    relationshipScoresByRole.value = const <String, RelationshipScoreModel>{};
    delayedConsequencesByRole.value = const <String, List<String>>{};
    activityHistory.value = const <ActivityHistoryModel>[];
    activityStreak.value = ActivityStreakModel.zero;
    activityXp.value = 0;
    flameMiniGameHistory.value = const <FlameMiniGameResultModel>[];
    flameMiniGameXp.value = 0;
    flameMiniGameScore.value = ScoreModel.zero;
    mentorPreference.value = MentorPreferenceModel.defaults;
    careerCoachState.value = CareerCoachStateModel.defaults;
    skillTreeProgressByRole.value = const <String, SkillTreeProgressModel>{};
    ScoreService.instance.reset();
    await _storage.clearProgress();
    await ProgressApiService.instance.saveProgress(const ProgressSnapshotModel());
  }

  Map<String, Set<String>> _mutableSetMap(Map<String, Set<String>> source) {
    return source.map((key, value) => MapEntry(key, Set<String>.from(value)));
  }

  Map<String, List<String>> _mutableListMap(Map<String, List<String>> source) {
    return source.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  Future<void> _saveSnapshot({
    required Map<String, RoleProgressModel> progressByRole,
    required ScoreModel totalScore,
    required int totalXp,
    required Set<String> badges,
    required Map<String, Set<String>> activeFlagsByRole,
    required Map<String, Set<String>> completedCleanupMissions,
    required Map<String, ReputationModel> roleReputation,
    required Map<String, int> miniGameAttempts,
    required Map<String, String> roleEndings,
    required Map<String, Set<String>> storyFlagsByRole,
    required Map<String, RelationshipScoreModel> relationshipScoresByRole,
    required Map<String, List<String>> delayedConsequencesByRole,
    required List<ActivityHistoryModel> activityHistory,
    required ActivityStreakModel activityStreak,
    required int activityXp,
    List<FlameMiniGameResultModel>? flameMiniGameHistory,
    int? flameMiniGameXp,
    ScoreModel? flameMiniGameScore,
    MentorPreferenceModel? mentorPreference,
    CareerCoachStateModel? careerCoachState,
    Map<String, SkillTreeProgressModel>? skillTreeProgressByRole,
  }) async {
    final snapshot = ProgressSnapshotModel(
      progressByRole: Map<String, RoleProgressModel>.unmodifiable(
        progressByRole,
      ),
      totalScore: totalScore,
      totalXp: totalXp,
      badges: Set<String>.unmodifiable(badges),
      activeFlagsByRole: _deepSetMap(activeFlagsByRole),
      completedCleanupMissions: _deepSetMap(completedCleanupMissions),
      roleReputation: Map<String, ReputationModel>.unmodifiable(roleReputation),
      miniGameAttempts: Map<String, int>.unmodifiable(miniGameAttempts),
      roleEndings: Map<String, String>.unmodifiable(roleEndings),
      storyFlagsByRole: _deepSetMap(storyFlagsByRole),
      relationshipScoresByRole:
          Map<String, RelationshipScoreModel>.unmodifiable(relationshipScoresByRole),
      delayedConsequencesByRole: _deepListMap(delayedConsequencesByRole),
      activityHistory: List<ActivityHistoryModel>.unmodifiable(activityHistory),
      activityStreak: activityStreak,
      activityXp: activityXp,
      flameMiniGameHistory: List<FlameMiniGameResultModel>.unmodifiable(
        flameMiniGameHistory ?? this.flameMiniGameHistory.value,
      ),
      flameMiniGameXp: flameMiniGameXp ?? this.flameMiniGameXp.value,
      flameMiniGameScore: flameMiniGameScore ?? this.flameMiniGameScore.value,
      mentorPreference: mentorPreference ?? this.mentorPreference.value,
      careerCoachState: careerCoachState ?? this.careerCoachState.value,
      skillTreeProgressByRole:
          skillTreeProgressByRole ?? this.skillTreeProgressByRole.value,
    );

    await _storage.saveProgress(snapshot);
    await ProgressApiService.instance.saveProgress(snapshot);
  }
}
