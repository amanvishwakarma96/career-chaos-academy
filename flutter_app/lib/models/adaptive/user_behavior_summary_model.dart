import '../score_model.dart';

class UserBehaviorSummaryModel {
  final int shortcutChoiceCount;
  final int ethicalChoiceCount;
  final int repeatedFailureCount;
  final List<String> strongSkills;
  final List<String> weakSkills;
  final List<String> preferredRoles;
  final Map<String, int> completedChaptersByRole;
  final Map<String, int> failedMiniGamesByRole;
  final List<String> behaviorPatterns;
  final DateTime? lastUpdatedAt;

  const UserBehaviorSummaryModel({
    this.shortcutChoiceCount = 0,
    this.ethicalChoiceCount = 0,
    this.repeatedFailureCount = 0,
    this.strongSkills = const <String>[],
    this.weakSkills = const <String>[],
    this.preferredRoles = const <String>[],
    this.completedChaptersByRole = const <String, int>{},
    this.failedMiniGamesByRole = const <String, int>{},
    this.behaviorPatterns = const <String>[],
    this.lastUpdatedAt,
  });

  static const empty = UserBehaviorSummaryModel();

  factory UserBehaviorSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserBehaviorSummaryModel(
      shortcutChoiceCount: _readNonNegativeInt(json['shortcutChoiceCount']),
      ethicalChoiceCount: _readNonNegativeInt(json['ethicalChoiceCount']),
      repeatedFailureCount: _readNonNegativeInt(json['repeatedFailureCount']),
      strongSkills: _readStringList(json['strongSkills']),
      weakSkills: _readStringList(json['weakSkills']),
      preferredRoles: _readStringList(json['preferredRoles']),
      completedChaptersByRole: _readIntMap(json['completedChaptersByRole']),
      failedMiniGamesByRole: _readIntMap(json['failedMiniGamesByRole']),
      behaviorPatterns: _readStringList(json['behaviorPatterns']),
      lastUpdatedAt: _readDate(json['lastUpdatedAt']),
    );
  }

  factory UserBehaviorSummaryModel.fromScore({
    required ScoreModel score,
    Map<String, int> completedChaptersByRole = const <String, int>{},
    Map<String, int> failedMiniGamesByRole = const <String, int>{},
    int shortcutChoiceCount = 0,
    int ethicalChoiceCount = 0,
  }) {
    final strong = <String>[];
    final weak = <String>[];
    final patterns = <String>[];

    void classify(String skill, int value) {
      if (value >= 8) strong.add(skill);
      if (value <= 1) weak.add(skill);
    }

    classify('skill', score.skill);
    classify('discipline', score.discipline);
    classify('ethics', score.ethics);
    classify('communication', score.communication);
    if (score.chaos >= 6) {
      weak.add('chaos_control');
      patterns.add('rising_chaos');
    }
    if (shortcutChoiceCount >= 2) patterns.add('shortcut_prone');
    if (ethicalChoiceCount >= 2) patterns.add('ethics_oriented');
    final totalFailures = failedMiniGamesByRole.values.fold<int>(0, (a, b) => a + b);
    if (totalFailures >= 2) patterns.add('repeated_failures');
    if (strong.contains('skill') && strong.contains('discipline')) patterns.add('high_performer');

    final preferred = completedChaptersByRole.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return UserBehaviorSummaryModel(
      shortcutChoiceCount: shortcutChoiceCount,
      ethicalChoiceCount: ethicalChoiceCount,
      repeatedFailureCount: totalFailures,
      strongSkills: strong,
      weakSkills: weak,
      preferredRoles: preferred.map((e) => e.key).take(3).toList(growable: false),
      completedChaptersByRole: completedChaptersByRole,
      failedMiniGamesByRole: failedMiniGamesByRole,
      behaviorPatterns: patterns,
      lastUpdatedAt: DateTime.now(),
    );
  }

  bool hasPattern(String pattern) => behaviorPatterns.contains(pattern);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shortcutChoiceCount': shortcutChoiceCount,
      'ethicalChoiceCount': ethicalChoiceCount,
      'repeatedFailureCount': repeatedFailureCount,
      'strongSkills': strongSkills,
      'weakSkills': weakSkills,
      'preferredRoles': preferredRoles,
      'completedChaptersByRole': completedChaptersByRole,
      'failedMiniGamesByRole': failedMiniGamesByRole,
      'behaviorPatterns': behaviorPatterns,
      'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
    };
  }

  static int _readNonNegativeInt(Object? value) {
    if (value is int && value >= 0) return value;
    if (value is num && value >= 0) return value.toInt();
    return 0;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  }

  static Map<String, int> _readIntMap(Object? value) {
    if (value is! Map) return const <String, int>{};
    final result = <String, int>{};
    value.forEach((key, item) {
      if (key is String && item is num && item >= 0) result[key] = item.toInt();
    });
    return Map<String, int>.unmodifiable(result);
  }

  static DateTime? _readDate(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
