class LearningAnalyticsEventModel {
  final String id;
  final String eventType;
  final String userId;
  final String userHash;
  final String organizationId;
  final String roleId;
  final String chapterId;
  final String choiceId;
  final String miniGameId;
  final String skillId;
  final int durationSeconds;
  final Map<String, dynamic> scoreDelta;
  final Map<String, dynamic> metadata;
  final String createdAt;

  const LearningAnalyticsEventModel({
    required this.id,
    required this.eventType,
    required this.userId,
    required this.userHash,
    required this.organizationId,
    required this.roleId,
    required this.chapterId,
    required this.choiceId,
    required this.miniGameId,
    required this.skillId,
    required this.durationSeconds,
    required this.scoreDelta,
    required this.metadata,
    required this.createdAt,
  });

  factory LearningAnalyticsEventModel.fromJson(Map<String, dynamic> json) {
    return LearningAnalyticsEventModel(
      id: _string(json['id'], fallback: 'event_${DateTime.now().microsecondsSinceEpoch}'),
      eventType: _string(json['eventType'], fallback: _string(json['name'], fallback: 'time_spent')),
      userId: _string(json['userId'], fallback: 'local_user'),
      userHash: _string(json['userHash']),
      organizationId: _string(json['organizationId']),
      roleId: _string(json['roleId'], fallback: 'unknown_role'),
      chapterId: _string(json['chapterId']),
      choiceId: _string(json['choiceId']),
      miniGameId: _string(json['miniGameId']),
      skillId: _string(json['skillId']),
      durationSeconds: _int(json['durationSeconds']),
      scoreDelta: _stringKeyMap(json['scoreDelta']),
      metadata: _stringKeyMap(json['metadata']),
      createdAt: _string(json['createdAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'eventType': eventType,
        'userId': userId,
        'userHash': userHash,
        'organizationId': organizationId,
        'roleId': roleId,
        'chapterId': chapterId,
        'choiceId': choiceId,
        'miniGameId': miniGameId,
        'skillId': skillId,
        'durationSeconds': durationSeconds,
        'scoreDelta': scoreDelta,
        'metadata': metadata,
        'createdAt': createdAt,
        'privacy': const <String, dynamic>{
          'sanitized': true,
          'rawPersonalTextStored': false,
          'adminVisibleUserHashOnly': true,
        },
      };
}

class LearningAnalyticsSettingsModel {
  final bool enabled;
  final bool shareAggregateWithAdmin;
  final int retentionDays;
  final String? updatedAt;

  const LearningAnalyticsSettingsModel({
    this.enabled = true,
    this.shareAggregateWithAdmin = true,
    this.retentionDays = 90,
    this.updatedAt,
  });

  factory LearningAnalyticsSettingsModel.fromJson(Map<String, dynamic> json) {
    return LearningAnalyticsSettingsModel(
      enabled: json['enabled'] != false,
      shareAggregateWithAdmin: json['shareAggregateWithAdmin'] != false,
      retentionDays: _clampInt(_int(json['retentionDays'], fallback: 90), 1, 365),
      updatedAt: json['updatedAt'] is String ? json['updatedAt'] as String : null,
    );
  }

  LearningAnalyticsSettingsModel copyWith({
    bool? enabled,
    bool? shareAggregateWithAdmin,
    int? retentionDays,
    String? updatedAt,
  }) {
    return LearningAnalyticsSettingsModel(
      enabled: enabled ?? this.enabled,
      shareAggregateWithAdmin: shareAggregateWithAdmin ?? this.shareAggregateWithAdmin,
      retentionDays: retentionDays ?? this.retentionDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'shareAggregateWithAdmin': shareAggregateWithAdmin,
        'retentionDays': retentionDays,
        'updatedAt': updatedAt,
      };
}

class RoleAnalyticsProgressModel {
  final String roleId;
  final int chapterStarts;
  final int chapterCompletions;
  final int choices;
  final int miniGameAttempts;
  final int timeSpentSeconds;
  final int progressPercent;
  final String? lastActiveAt;

  const RoleAnalyticsProgressModel({
    required this.roleId,
    required this.chapterStarts,
    required this.chapterCompletions,
    required this.choices,
    required this.miniGameAttempts,
    required this.timeSpentSeconds,
    required this.progressPercent,
    this.lastActiveAt,
  });

  factory RoleAnalyticsProgressModel.fromJson(Map<String, dynamic> json) {
    return RoleAnalyticsProgressModel(
      roleId: _string(json['roleId'], fallback: 'unknown_role'),
      chapterStarts: _int(json['chapterStarts']),
      chapterCompletions: _int(json['chapterCompletions']),
      choices: _int(json['choices']),
      miniGameAttempts: _int(json['miniGameAttempts']),
      timeSpentSeconds: _int(json['timeSpentSeconds']),
      progressPercent: _clampInt(_int(json['progressPercent']), 0, 100),
      lastActiveAt: json['lastActiveAt'] is String ? json['lastActiveAt'] as String : null,
    );
  }
}

class LearningAnalyticsSummaryModel {
  final int totalEvents;
  final int totalChapterStarts;
  final int totalChapterCompletions;
  final int totalChoiceSelections;
  final int totalMiniGameAttempts;
  final int totalTimeSpentSeconds;
  final int averageCompletionPerRole;
  final Map<String, RoleAnalyticsProgressModel> roleProgress;
  final Map<String, int> skillImprovement;

  const LearningAnalyticsSummaryModel({
    required this.totalEvents,
    required this.totalChapterStarts,
    required this.totalChapterCompletions,
    required this.totalChoiceSelections,
    required this.totalMiniGameAttempts,
    required this.totalTimeSpentSeconds,
    required this.averageCompletionPerRole,
    required this.roleProgress,
    required this.skillImprovement,
  });

  factory LearningAnalyticsSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = _stringKeyMap(json['roleProgress']);
    final roles = <String, RoleAnalyticsProgressModel>{};
    rawRoles.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        roles[key] = RoleAnalyticsProgressModel.fromJson(value);
      } else if (value is Map) {
        roles[key] = RoleAnalyticsProgressModel.fromJson(Map<String, dynamic>.from(value));
      }
    });
    final rawSkills = _stringKeyMap(json['skillImprovement']);
    return LearningAnalyticsSummaryModel(
      totalEvents: _int(json['totalEvents']),
      totalChapterStarts: _int(json['totalChapterStarts']),
      totalChapterCompletions: _int(json['totalChapterCompletions']),
      totalChoiceSelections: _int(json['totalChoiceSelections']),
      totalMiniGameAttempts: _int(json['totalMiniGameAttempts']),
      totalTimeSpentSeconds: _int(json['totalTimeSpentSeconds']),
      averageCompletionPerRole: _clampInt(_int(json['averageCompletionPerRole']), 0, 100),
      roleProgress: Map<String, RoleAnalyticsProgressModel>.unmodifiable(roles),
      skillImprovement: rawSkills.map((key, value) => MapEntry(key, _int(value))),
    );
  }

  static const empty = LearningAnalyticsSummaryModel(
    totalEvents: 0,
    totalChapterStarts: 0,
    totalChapterCompletions: 0,
    totalChoiceSelections: 0,
    totalMiniGameAttempts: 0,
    totalTimeSpentSeconds: 0,
    averageCompletionPerRole: 0,
    roleProgress: <String, RoleAnalyticsProgressModel>{},
    skillImprovement: <String, int>{},
  );
}

class PersonalAnalyticsDashboardModel {
  final String userId;
  final bool analyticsEnabled;
  final String generatedAt;
  final LearningAnalyticsSummaryModel summary;
  final List<LearningAnalyticsEventModel> recentEvents;
  final Map<String, dynamic> privacy;
  final Map<String, dynamic> performance;

  const PersonalAnalyticsDashboardModel({
    required this.userId,
    required this.analyticsEnabled,
    required this.generatedAt,
    required this.summary,
    required this.recentEvents,
    required this.privacy,
    required this.performance,
  });

  factory PersonalAnalyticsDashboardModel.fromJson(Map<String, dynamic> json) {
    return PersonalAnalyticsDashboardModel(
      userId: _string(json['userId'], fallback: 'local_user'),
      analyticsEnabled: json['analyticsEnabled'] != false,
      generatedAt: _string(json['generatedAt'], fallback: DateTime.now().toIso8601String()),
      summary: json['summary'] is Map<String, dynamic>
          ? LearningAnalyticsSummaryModel.fromJson(json['summary'] as Map<String, dynamic>)
          : LearningAnalyticsSummaryModel.empty,
      recentEvents: _mapList(json['recentEvents']).map(LearningAnalyticsEventModel.fromJson).toList(growable: false),
      privacy: _stringKeyMap(json['privacy']),
      performance: _stringKeyMap(json['performance']),
    );
  }
}

class AdminAnalyticsDashboardModel {
  final LearningAnalyticsSummaryModel summary;
  final Map<String, int> eventCountsByType;
  final Map<String, int> roleCounts;
  final Map<String, dynamic> privacy;
  final Map<String, dynamic> performance;

  const AdminAnalyticsDashboardModel({
    required this.summary,
    required this.eventCountsByType,
    required this.roleCounts,
    required this.privacy,
    required this.performance,
  });

  factory AdminAnalyticsDashboardModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] is Map<String, dynamic> ? json['summary'] as Map<String, dynamic> : <String, dynamic>{};
    return AdminAnalyticsDashboardModel(
      summary: LearningAnalyticsSummaryModel.fromJson(summaryJson),
      eventCountsByType: _stringKeyMap(json['eventCountsByType']).map((key, value) => MapEntry(key, _int(value))),
      roleCounts: _stringKeyMap(json['roleCounts']).map((key, value) => MapEntry(key, _int(value))),
      privacy: _stringKeyMap(json['privacy']),
      performance: _stringKeyMap(json['performance']),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

int _clampInt(int value, int min, int max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

Map<String, dynamic> _stringKeyMap(Object? value) {
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList(growable: false);
}
