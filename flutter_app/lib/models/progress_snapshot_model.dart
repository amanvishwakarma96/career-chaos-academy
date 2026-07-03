import 'activity_model.dart';
import 'flame_mini_game_model.dart';
import 'mentor/mentor_model.dart';
import 'future_scope/content_cache_state_model.dart';
import 'adaptive/user_behavior_summary_model.dart';
import 'adaptive/adaptive_story_model.dart';
import 'career_coach/user_skill_profile_model.dart';
import 'relationship_score_model.dart';
import 'reputation_model.dart';
import 'role_progress_model.dart';
import 'score_model.dart';
import 'skill_tree/skill_tree_model.dart';

class ProgressSnapshotModel {
  final Map<String, RoleProgressModel> progressByRole;
  final ScoreModel totalScore;
  final int totalXp;
  final Set<String> badges;
  final Map<String, Set<String>> activeFlagsByRole;
  final Map<String, Set<String>> completedCleanupMissions;
  final Map<String, ReputationModel> roleReputation;
  final Map<String, int> miniGameAttempts;
  final Map<String, String> roleEndings;
  final Map<String, Set<String>> storyFlagsByRole;
  final Map<String, RelationshipScoreModel> relationshipScoresByRole;
  final Map<String, List<String>> delayedConsequencesByRole;
  final List<ActivityHistoryModel> activityHistory;
  final ActivityStreakModel activityStreak;
  final int activityXp;
  final List<FlameMiniGameResultModel> flameMiniGameHistory;
  final int flameMiniGameXp;
  final ScoreModel flameMiniGameScore;
  final MentorPreferenceModel mentorPreference;
  final ContentCacheStateModel contentCacheState;
  final Map<String, bool> featureFlagOverrides;
  final UserBehaviorSummaryModel userBehaviorSummary;
  final List<AdaptiveStoryDraftModel> adaptiveStoryDrafts;
  final CareerCoachStateModel careerCoachState;
  final Map<String, SkillTreeProgressModel> skillTreeProgressByRole;

  const ProgressSnapshotModel({
    this.progressByRole = const <String, RoleProgressModel>{},
    this.totalScore = ScoreModel.zero,
    this.totalXp = 0,
    this.badges = const <String>{},
    this.activeFlagsByRole = const <String, Set<String>>{},
    this.completedCleanupMissions = const <String, Set<String>>{},
    this.roleReputation = const <String, ReputationModel>{},
    this.miniGameAttempts = const <String, int>{},
    this.roleEndings = const <String, String>{},
    this.storyFlagsByRole = const <String, Set<String>>{},
    this.relationshipScoresByRole = const <String, RelationshipScoreModel>{},
    this.delayedConsequencesByRole = const <String, List<String>>{},
    this.activityHistory = const <ActivityHistoryModel>[],
    this.activityStreak = ActivityStreakModel.zero,
    this.activityXp = 0,
    this.flameMiniGameHistory = const <FlameMiniGameResultModel>[],
    this.flameMiniGameXp = 0,
    this.flameMiniGameScore = ScoreModel.zero,
    this.mentorPreference = MentorPreferenceModel.defaults,
    this.contentCacheState = ContentCacheStateModel.defaults,
    this.featureFlagOverrides = const <String, bool>{},
    this.userBehaviorSummary = UserBehaviorSummaryModel.empty,
    this.adaptiveStoryDrafts = const <AdaptiveStoryDraftModel>[],
    this.careerCoachState = CareerCoachStateModel.defaults,
    this.skillTreeProgressByRole = const <String, SkillTreeProgressModel>{},
  });

  factory ProgressSnapshotModel.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progressByRole'];
    final progressByRole = <String, RoleProgressModel>{};

    if (progressJson is Map<String, dynamic>) {
      progressJson.forEach((roleId, value) {
        if (value is Map<String, dynamic>) {
          progressByRole[roleId] = RoleProgressModel.fromJson(
            value,
            fallbackRoleId: roleId,
          );
        }
      });
    }

    final storedTotalScore = json['totalScore'];
    final totalScore = storedTotalScore is Map<String, dynamic>
        ? ScoreModel.fromJson(storedTotalScore)
        : calculateTotalScore(progressByRole);

    final storedXp = json['totalXp'];
    final totalXp = storedXp is int && storedXp >= 0
        ? storedXp
        : calculateTotalXp(progressByRole);

    return ProgressSnapshotModel(
      progressByRole: Map<String, RoleProgressModel>.unmodifiable(
        progressByRole,
      ),
      totalScore: totalScore,
      totalXp: totalXp,
      badges: _readStringSet(json['badges']),
      activeFlagsByRole: _readStringSetMap(json['activeFlagsByRole']),
      completedCleanupMissions: _readStringSetMap(
        json['completedCleanupMissions'],
      ),
      roleReputation: _readReputationMap(json['roleReputation']),
      miniGameAttempts: _readIntMap(json['miniGameAttempts']),
      roleEndings: _readStringMap(json['roleEndings']),
      storyFlagsByRole: _readStringSetMap(json['storyFlagsByRole']),
      relationshipScoresByRole: _readRelationshipScoreMap(
        json['relationshipScoresByRole'],
      ),
      delayedConsequencesByRole: _readStringListMap(
        json['delayedConsequencesByRole'],
      ),
      activityHistory: _readActivityHistory(json['activityHistory']),
      activityStreak: _readActivityStreak(json['activityStreak']),
      activityXp: _readNonNegativeInt(json['activityXp']),
      flameMiniGameHistory: _readFlameMiniGameHistory(json['flameMiniGameHistory']),
      flameMiniGameXp: _readNonNegativeInt(json['flameMiniGameXp']),
      flameMiniGameScore: json['flameMiniGameScore'] is Map<String, dynamic>
          ? ScoreModel.fromJson(json['flameMiniGameScore'] as Map<String, dynamic>)
          : ScoreModel.zero,
      mentorPreference: json['mentorPreference'] is Map<String, dynamic>
          ? MentorPreferenceModel.fromJson(json['mentorPreference'] as Map<String, dynamic>)
          : MentorPreferenceModel.defaults,
      contentCacheState: json['contentCacheState'] is Map<String, dynamic>
          ? ContentCacheStateModel.fromJson(json['contentCacheState'] as Map<String, dynamic>)
          : ContentCacheStateModel.defaults,
      featureFlagOverrides: _readBoolMap(json['featureFlagOverrides']),
      userBehaviorSummary: json['userBehaviorSummary'] is Map<String, dynamic>
          ? UserBehaviorSummaryModel.fromJson(json['userBehaviorSummary'] as Map<String, dynamic>)
          : UserBehaviorSummaryModel.empty,
      adaptiveStoryDrafts: _readAdaptiveStoryDrafts(json['adaptiveStoryDrafts']),
      careerCoachState: json['careerCoachState'] is Map<String, dynamic>
          ? CareerCoachStateModel.fromJson(json['careerCoachState'] as Map<String, dynamic>)
          : CareerCoachStateModel.defaults,
      skillTreeProgressByRole: _readSkillTreeProgressMap(json['skillTreeProgressByRole']),
    );
  }

  static ScoreModel calculateTotalScore(
    Map<String, RoleProgressModel> progressByRole,
  ) {
    return progressByRole.values.fold<ScoreModel>(
      ScoreModel.zero,
      (total, roleProgress) => total.add(roleProgress.roleScore),
    );
  }

  static int calculateTotalXp(Map<String, RoleProgressModel> progressByRole) {
    return progressByRole.values.fold<int>(
      0,
      (total, roleProgress) => total + roleProgress.roleXp,
    );
  }

  static Set<String> _readStringSet(Object? value) {
    if (value is! List) {
      return <String>{};
    }

    return value.whereType<String>().toSet();
  }

  static Map<String, Set<String>> _readStringSetMap(Object? value) {
    if (value is! Map) {
      return const <String, Set<String>>{};
    }
    final result = <String, Set<String>>{};
    value.forEach((key, item) {
      if (key is String) {
        result[key] = _readStringSet(item);
      }
    });
    return Map<String, Set<String>>.unmodifiable(result.map(
      (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
    ));
  }

  static Map<String, ReputationModel> _readReputationMap(Object? value) {
    if (value is! Map) {
      return const <String, ReputationModel>{};
    }
    final result = <String, ReputationModel>{};
    value.forEach((key, item) {
      if (key is String && item is Map<String, dynamic>) {
        result[key] = ReputationModel.fromJson(item);
      }
    });
    return Map<String, ReputationModel>.unmodifiable(result);
  }

  static Map<String, int> _readIntMap(Object? value) {
    if (value is! Map) {
      return const <String, int>{};
    }
    final result = <String, int>{};
    value.forEach((key, item) {
      if (key is String && item is int && item >= 0) {
        result[key] = item;
      }
    });
    return Map<String, int>.unmodifiable(result);
  }


  static int _readNonNegativeInt(Object? value) {
    if (value is int && value >= 0) {
      return value;
    }
    if (value is num && value >= 0) {
      return value.toInt();
    }
    return 0;
  }

  static List<ActivityHistoryModel> _readActivityHistory(Object? value) {
    if (value is! List) {
      return const <ActivityHistoryModel>[];
    }
    final result = <ActivityHistoryModel>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        result.add(ActivityHistoryModel.fromJson(item));
      }
    }
    return List<ActivityHistoryModel>.unmodifiable(result);
  }


  static List<FlameMiniGameResultModel> _readFlameMiniGameHistory(Object? value) {
    if (value is! List) {
      return const <FlameMiniGameResultModel>[];
    }
    final result = <FlameMiniGameResultModel>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        result.add(FlameMiniGameResultModel.fromJson(item));
      }
    }
    return List<FlameMiniGameResultModel>.unmodifiable(result);
  }



  static List<AdaptiveStoryDraftModel> _readAdaptiveStoryDrafts(Object? value) {
    if (value is! List) {
      return const <AdaptiveStoryDraftModel>[];
    }
    final result = <AdaptiveStoryDraftModel>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        result.add(AdaptiveStoryDraftModel.fromJson(item));
      }
    }
    return List<AdaptiveStoryDraftModel>.unmodifiable(result);
  }

  static ActivityStreakModel _readActivityStreak(Object? value) {
    if (value is Map<String, dynamic>) {
      return ActivityStreakModel.fromJson(value);
    }
    return ActivityStreakModel.zero;
  }

  static Map<String, RelationshipScoreModel> _readRelationshipScoreMap(Object? value) {
    if (value is! Map) {
      return const <String, RelationshipScoreModel>{};
    }
    final result = <String, RelationshipScoreModel>{};
    value.forEach((key, item) {
      if (key is String && item is Map<String, dynamic>) {
        result[key] = RelationshipScoreModel.fromJson(item);
      }
    });
    return Map<String, RelationshipScoreModel>.unmodifiable(result);
  }

  static Map<String, List<String>> _readStringListMap(Object? value) {
    if (value is! Map) {
      return const <String, List<String>>{};
    }
    final result = <String, List<String>>{};
    value.forEach((key, item) {
      if (key is String && item is List) {
        result[key] = item.whereType<String>().map((entry) => entry.trim()).where((entry) => entry.isNotEmpty).toList(growable: false);
      }
    });
    return Map<String, List<String>>.unmodifiable(result.map((key, value) => MapEntry(key, List<String>.unmodifiable(value))));
  }


  static Map<String, SkillTreeProgressModel> _readSkillTreeProgressMap(Object? value) {
    if (value is! Map) {
      return const <String, SkillTreeProgressModel>{};
    }
    final result = <String, SkillTreeProgressModel>{};
    value.forEach((key, item) {
      if (key is String && item is Map<String, dynamic>) {
        result[key] = SkillTreeProgressModel.fromJson(item, fallbackRoleId: key);
      }
    });
    return Map<String, SkillTreeProgressModel>.unmodifiable(result);
  }

  static Map<String, bool> _readBoolMap(Object? value) {
    if (value is! Map) {
      return const <String, bool>{};
    }
    final result = <String, bool>{};
    value.forEach((key, item) {
      if (key is String && item is bool) {
        result[key] = item;
      }
    });
    return Map<String, bool>.unmodifiable(result);
  }

  static Map<String, String> _readStringMap(Object? value) {
    if (value is! Map) {
      return const <String, String>{};
    }
    final result = <String, String>{};
    value.forEach((key, item) {
      if (key is String && item is String && item.trim().isNotEmpty) {
        result[key] = item;
      }
    });
    return Map<String, String>.unmodifiable(result);
  }

  Map<String, dynamic> toJson() {
    final badgeList = badges.toList()..sort();

    return <String, dynamic>{
      'version': 13,
      'progressByRole': progressByRole.map(
        (roleId, progress) => MapEntry(roleId, progress.toJson()),
      ),
      'totalScore': totalScore.toJson(),
      'totalXp': totalXp,
      'badges': badgeList,
      'activeFlagsByRole': _stringSetMapToJson(activeFlagsByRole),
      'completedCleanupMissions': _stringSetMapToJson(completedCleanupMissions),
      'roleReputation': roleReputation.map(
        (roleId, reputation) => MapEntry(roleId, reputation.toJson()),
      ),
      'miniGameAttempts': miniGameAttempts,
      'roleEndings': roleEndings,
      'storyFlagsByRole': _stringSetMapToJson(storyFlagsByRole),
      'relationshipScoresByRole': relationshipScoresByRole.map(
        (roleId, relationship) => MapEntry(roleId, relationship.toJson()),
      ),
      'delayedConsequencesByRole': delayedConsequencesByRole,
      'activityHistory': activityHistory.map((item) => item.toJson()).toList(growable: false),
      'activityStreak': activityStreak.toJson(),
      'activityXp': activityXp,
      'flameMiniGameHistory': flameMiniGameHistory.map((item) => item.toJson()).toList(growable: false),
      'flameMiniGameXp': flameMiniGameXp,
      'flameMiniGameScore': flameMiniGameScore.toJson(),
      'mentorPreference': mentorPreference.toJson(),
      'contentCacheState': contentCacheState.toJson(),
      'featureFlagOverrides': featureFlagOverrides,
      'userBehaviorSummary': userBehaviorSummary.toJson(),
      'adaptiveStoryDrafts': adaptiveStoryDrafts.map((item) => item.toJson()).toList(growable: false),
      'careerCoachState': careerCoachState.toJson(),
      'skillTreeProgressByRole': skillTreeProgressByRole.map((roleId, progress) => MapEntry(roleId, progress.toJson())),
    };
  }

  static Map<String, List<String>> _stringSetMapToJson(
    Map<String, Set<String>> value,
  ) {
    return value.map((key, items) {
      final list = items.toList()..sort();
      return MapEntry(key, list);
    });
  }

  ProgressSnapshotModel copyWith({
    Map<String, RoleProgressModel>? progressByRole,
    ScoreModel? totalScore,
    int? totalXp,
    Set<String>? badges,
    Map<String, Set<String>>? activeFlagsByRole,
    Map<String, Set<String>>? completedCleanupMissions,
    Map<String, ReputationModel>? roleReputation,
    Map<String, int>? miniGameAttempts,
    Map<String, String>? roleEndings,
    Map<String, Set<String>>? storyFlagsByRole,
    Map<String, RelationshipScoreModel>? relationshipScoresByRole,
    Map<String, List<String>>? delayedConsequencesByRole,
    List<ActivityHistoryModel>? activityHistory,
    ActivityStreakModel? activityStreak,
    int? activityXp,
    List<FlameMiniGameResultModel>? flameMiniGameHistory,
    int? flameMiniGameXp,
    ScoreModel? flameMiniGameScore,
    MentorPreferenceModel? mentorPreference,
    ContentCacheStateModel? contentCacheState,
    Map<String, bool>? featureFlagOverrides,
    UserBehaviorSummaryModel? userBehaviorSummary,
    List<AdaptiveStoryDraftModel>? adaptiveStoryDrafts,
    CareerCoachStateModel? careerCoachState,
    Map<String, SkillTreeProgressModel>? skillTreeProgressByRole,
  }) {
    return ProgressSnapshotModel(
      progressByRole: progressByRole ?? this.progressByRole,
      totalScore: totalScore ?? this.totalScore,
      totalXp: totalXp ?? this.totalXp,
      badges: badges ?? this.badges,
      activeFlagsByRole: activeFlagsByRole ?? this.activeFlagsByRole,
      completedCleanupMissions:
          completedCleanupMissions ?? this.completedCleanupMissions,
      roleReputation: roleReputation ?? this.roleReputation,
      miniGameAttempts: miniGameAttempts ?? this.miniGameAttempts,
      roleEndings: roleEndings ?? this.roleEndings,
      storyFlagsByRole: storyFlagsByRole ?? this.storyFlagsByRole,
      relationshipScoresByRole:
          relationshipScoresByRole ?? this.relationshipScoresByRole,
      delayedConsequencesByRole:
          delayedConsequencesByRole ?? this.delayedConsequencesByRole,
      activityHistory: activityHistory ?? this.activityHistory,
      activityStreak: activityStreak ?? this.activityStreak,
      activityXp: activityXp ?? this.activityXp,
      flameMiniGameHistory:
          flameMiniGameHistory ?? this.flameMiniGameHistory,
      flameMiniGameXp: flameMiniGameXp ?? this.flameMiniGameXp,
      flameMiniGameScore: flameMiniGameScore ?? this.flameMiniGameScore,
      mentorPreference: mentorPreference ?? this.mentorPreference,
      contentCacheState: contentCacheState ?? this.contentCacheState,
      featureFlagOverrides: featureFlagOverrides ?? this.featureFlagOverrides,
      userBehaviorSummary: userBehaviorSummary ?? this.userBehaviorSummary,
      adaptiveStoryDrafts: adaptiveStoryDrafts ?? this.adaptiveStoryDrafts,
      careerCoachState: careerCoachState ?? this.careerCoachState,
      skillTreeProgressByRole:
          skillTreeProgressByRole ?? this.skillTreeProgressByRole,
    );
  }
}
