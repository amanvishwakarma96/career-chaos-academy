import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning_analytics_model.dart';
import 'api_client.dart';
import 'device_user_service.dart';

class LearningAnalyticsEvents {
  const LearningAnalyticsEvents._();

  static const chapterStarted = 'chapter_started';
  static const chapterCompleted = 'chapter_completed';
  static const choiceSelected = 'choice_selected';
  static const miniGameAttempt = 'mini_game_attempt';
  static const timeSpent = 'time_spent';
  static const roleProgress = 'role_progress';
  static const skillImprovement = 'skill_improvement';
}

class LearningAnalyticsService {
  LearningAnalyticsService._();

  static final LearningAnalyticsService instance = LearningAnalyticsService._();
  static const String _eventsKey = 'career_chaos_learning_analytics_events_v1';
  static const String _settingsKey = 'career_chaos_learning_analytics_settings_v1';

  Future<LearningAnalyticsSettingsModel> loadSettings() async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/users/${Uri.encodeComponent(userId)}/analytics/settings');
        final raw = json['settings'];
        if (raw is Map<String, dynamic>) return LearningAnalyticsSettingsModel.fromJson(raw);
      } on Object {
        // Local setting fallback below.
      }
    }
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_settingsKey);
    if (raw == null || raw.trim().isEmpty) return const LearningAnalyticsSettingsModel();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return LearningAnalyticsSettingsModel.fromJson(decoded);
    } on Object {
      await preferences.remove(_settingsKey);
    }
    return const LearningAnalyticsSettingsModel();
  }

  Future<LearningAnalyticsSettingsModel> saveSettings(LearningAnalyticsSettingsModel settings) async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    final next = settings.copyWith(updatedAt: DateTime.now().toIso8601String());
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_settingsKey, jsonEncode(next.toJson()));
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/users/${Uri.encodeComponent(userId)}/analytics/settings', next.toJson());
        final raw = json['settings'];
        if (raw is Map<String, dynamic>) return LearningAnalyticsSettingsModel.fromJson(raw);
      } on Object {
        // Local save is already complete.
      }
    }
    return next;
  }

  Future<void> trackChapterStarted({
    required String roleId,
    required String chapterId,
    String organizationId = '',
  }) async {
    await track(
      eventType: LearningAnalyticsEvents.chapterStarted,
      roleId: roleId,
      chapterId: chapterId,
      organizationId: organizationId,
    );
  }

  Future<void> trackChapterCompleted({
    required String roleId,
    required String chapterId,
    required Map<String, dynamic> scoreDelta,
    int timeSpentSeconds = 0,
  }) async {
    await track(
      eventType: LearningAnalyticsEvents.chapterCompleted,
      roleId: roleId,
      chapterId: chapterId,
      durationSeconds: timeSpentSeconds,
      scoreDelta: scoreDelta,
    );
    await trackRoleProgress(roleId: roleId, chapterId: chapterId);
    await trackSkillImprovement(roleId: roleId, chapterId: chapterId, scoreDelta: scoreDelta);
  }

  Future<void> trackChoiceSelected({
    required String roleId,
    required String chapterId,
    required String choiceId,
    required Map<String, dynamic> scoreDelta,
  }) async {
    await track(
      eventType: LearningAnalyticsEvents.choiceSelected,
      roleId: roleId,
      chapterId: chapterId,
      choiceId: choiceId,
      scoreDelta: scoreDelta,
    );
  }

  Future<void> trackMiniGameAttempt({
    required String roleId,
    required String chapterId,
    required String miniGameId,
    required bool passed,
    required Map<String, dynamic> scoreDelta,
    int timeSpentSeconds = 0,
  }) async {
    await track(
      eventType: LearningAnalyticsEvents.miniGameAttempt,
      roleId: roleId,
      chapterId: chapterId,
      miniGameId: miniGameId,
      durationSeconds: timeSpentSeconds,
      scoreDelta: scoreDelta,
      metadata: <String, dynamic>{'passed': passed},
    );
  }

  Future<void> trackTimeSpent({
    required String roleId,
    required String chapterId,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    await track(
      eventType: LearningAnalyticsEvents.timeSpent,
      roleId: roleId,
      chapterId: chapterId,
      durationSeconds: seconds,
    );
  }

  Future<void> trackRoleProgress({required String roleId, String chapterId = ''}) async {
    await track(
      eventType: LearningAnalyticsEvents.roleProgress,
      roleId: roleId,
      chapterId: chapterId,
    );
  }

  Future<void> trackSkillImprovement({
    required String roleId,
    String chapterId = '',
    required Map<String, dynamic> scoreDelta,
  }) async {
    for (final entry in scoreDelta.entries) {
      await track(
        eventType: LearningAnalyticsEvents.skillImprovement,
        roleId: roleId,
        chapterId: chapterId,
        skillId: entry.key,
        scoreDelta: <String, dynamic>{entry.key: entry.value},
      );
    }
  }

  Future<void> track({
    required String eventType,
    String roleId = '',
    String chapterId = '',
    String choiceId = '',
    String miniGameId = '',
    String skillId = '',
    String organizationId = '',
    int durationSeconds = 0,
    Map<String, dynamic> scoreDelta = const <String, dynamic>{},
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final settings = await loadSettings();
    if (!settings.enabled) return;
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    final event = LearningAnalyticsEventModel(
      id: 'event_${DateTime.now().microsecondsSinceEpoch}',
      eventType: eventType,
      userId: userId,
      userHash: '',
      organizationId: organizationId,
      roleId: roleId,
      chapterId: chapterId,
      choiceId: choiceId,
      miniGameId: miniGameId,
      skillId: skillId,
      durationSeconds: durationSeconds,
      scoreDelta: _sanitizeMap(scoreDelta),
      metadata: _sanitizeMap(metadata),
      createdAt: DateTime.now().toIso8601String(),
    );
    await _appendLocalEvent(event);
    if (ApiClient.instance.isEnabled) {
      try {
        await ApiClient.instance.postMap('/api/analytics/events', event.toJson());
      } on Object {
        // Local analytics remain available and synced behaviour can be added later.
      }
    }
  }

  Future<PersonalAnalyticsDashboardModel> loadPersonalDashboard() async {
    final userId = await DeviceUserService.instance.getOrCreateUserId();
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/users/${Uri.encodeComponent(userId)}/analytics/dashboard');
        return PersonalAnalyticsDashboardModel.fromJson(json);
      } on Object {
        // Local fallback below.
      }
    }
    final settings = await loadSettings();
    final events = await _readLocalEvents();
    final summary = _buildLocalSummary(events);
    return PersonalAnalyticsDashboardModel(
      userId: userId,
      analyticsEnabled: settings.enabled,
      generatedAt: DateTime.now().toIso8601String(),
      summary: summary,
      recentEvents: events.take(25).toList(growable: false),
      privacy: const <String, dynamic>{
        'personalDashboardUsesOwnEventsOnly': true,
        'sensitiveMetadataFiltered': true,
        'canDisableAnalytics': true,
      },
      performance: <String, dynamic>{
        'eventCount': events.length,
        'aggregationMode': 'local_single_pass',
        'appPerformanceImpact': 'low_capped_local_history',
      },
    );
  }

  Future<AdminAnalyticsDashboardModel> loadAdminDashboard() async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/admin/analytics/dashboard');
        return AdminAnalyticsDashboardModel.fromJson(json);
      } on Object {
        // Local aggregate fallback below.
      }
    }
    final events = await _readLocalEvents();
    final summary = _buildLocalSummary(events);
    return AdminAnalyticsDashboardModel(
      summary: summary,
      eventCountsByType: _countBy(events, (event) => event.eventType),
      roleCounts: _countBy(events, (event) => event.roleId),
      privacy: const <String, dynamic>{
        'rawUserIdsExposed': false,
        'namesEmailsAnswersExcluded': true,
        'aggregateOnly': true,
      },
      performance: <String, dynamic>{
        'eventCount': events.length,
        'aggregationMode': 'local_single_pass',
      },
    );
  }

  Future<void> _appendLocalEvent(LearningAnalyticsEventModel event) async {
    final events = await _readLocalEvents();
    final next = <LearningAnalyticsEventModel>[event, ...events].take(500).toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_eventsKey, jsonEncode(next.map((item) => item.toJson()).toList(growable: false)));
  }

  Future<List<LearningAnalyticsEventModel>> _readLocalEvents() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_eventsKey);
    if (raw == null || raw.trim().isEmpty) return const <LearningAnalyticsEventModel>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map>().map((item) => LearningAnalyticsEventModel.fromJson(Map<String, dynamic>.from(item))).toList(growable: false);
      }
    } on Object {
      await preferences.remove(_eventsKey);
    }
    return const <LearningAnalyticsEventModel>[];
  }

  LearningAnalyticsSummaryModel _buildLocalSummary(List<LearningAnalyticsEventModel> events) {
    final roleProgress = <String, _RoleAccumulator>{};
    final skillImprovement = <String, int>{};
    var starts = 0;
    var completions = 0;
    var choices = 0;
    var miniGames = 0;
    var time = 0;

    for (final event in events) {
      final role = roleProgress.putIfAbsent(event.roleId.isEmpty ? 'unknown_role' : event.roleId, () => _RoleAccumulator(event.roleId));
      time += event.durationSeconds;
      role.timeSpentSeconds += event.durationSeconds;
      role.lastActiveAt = event.createdAt;
      switch (event.eventType) {
        case LearningAnalyticsEvents.chapterStarted:
          starts += 1;
          role.chapterStarts += 1;
          break;
        case LearningAnalyticsEvents.chapterCompleted:
          completions += 1;
          role.chapterCompletions += 1;
          break;
        case LearningAnalyticsEvents.choiceSelected:
          choices += 1;
          role.choices += 1;
          break;
        case LearningAnalyticsEvents.miniGameAttempt:
          miniGames += 1;
          role.miniGameAttempts += 1;
          break;
      }
      for (final score in event.scoreDelta.entries) {
        skillImprovement[score.key] = (skillImprovement[score.key] ?? 0) + _int(score.value);
      }
    }

    final roles = roleProgress.map((key, value) {
      final percent = _clampInt(value.chapterStarts <= 0 ? 0 : ((value.chapterCompletions / value.chapterStarts) * 100).round(), 0, 100);
      return MapEntry(
        key,
        RoleAnalyticsProgressModel(
          roleId: key,
          chapterStarts: value.chapterStarts,
          chapterCompletions: value.chapterCompletions,
          choices: value.choices,
          miniGameAttempts: value.miniGameAttempts,
          timeSpentSeconds: value.timeSpentSeconds,
          progressPercent: percent,
          lastActiveAt: value.lastActiveAt,
        ),
      );
    });
    final average = roles.isEmpty ? 0 : (roles.values.fold<int>(0, (sum, role) => sum + role.progressPercent) / roles.length).round();
    return LearningAnalyticsSummaryModel(
      totalEvents: events.length,
      totalChapterStarts: starts,
      totalChapterCompletions: completions,
      totalChoiceSelections: choices,
      totalMiniGameAttempts: miniGames,
      totalTimeSpentSeconds: time,
      averageCompletionPerRole: average,
      roleProgress: Map<String, RoleAnalyticsProgressModel>.unmodifiable(roles),
      skillImprovement: Map<String, int>.unmodifiable(skillImprovement),
    );
  }

  Map<String, int> _countBy(List<LearningAnalyticsEventModel> events, String Function(LearningAnalyticsEventModel event) selector) {
    final result = <String, int>{};
    for (final event in events) {
      final key = selector(event);
      if (key.isEmpty) continue;
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key.toLowerCase();
      final blocked = key.contains('email') || key.contains('phone') || key.contains('password') || key.contains('token') || key.contains('name') || key.contains('message') || key.contains('answer');
      if (!blocked) result[entry.key] = entry.value;
    }
    return result;
  }

  int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _RoleAccumulator {
  _RoleAccumulator(this.roleId);

  final String roleId;
  int chapterStarts = 0;
  int chapterCompletions = 0;
  int choices = 0;
  int miniGameAttempts = 0;
  int timeSpentSeconds = 0;
  String? lastActiveAt;
}
