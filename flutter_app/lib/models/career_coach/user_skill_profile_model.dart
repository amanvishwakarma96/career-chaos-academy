import '../score_model.dart';

class CoachMentorStyleModel {
  final String id;
  final String name;
  final String tone;
  final String description;
  final String encouragement;
  final String safetyBoundary;

  const CoachMentorStyleModel({
    required this.id,
    required this.name,
    required this.tone,
    this.description = '',
    this.encouragement = '',
    this.safetyBoundary = '',
  });

  factory CoachMentorStyleModel.fromJson(Map<String, dynamic> json) {
    return CoachMentorStyleModel(
      id: _readString(json['id'], 'calm_teacher'),
      name: _readString(json['name'], 'Calm Teacher'),
      tone: _readString(json['tone'], 'patient_explainer'),
      description: _readString(json['description']),
      encouragement: _readString(json['encouragement']),
      safetyBoundary: _readString(json['safetyBoundary']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'tone': tone,
      'description': description,
      'encouragement': encouragement,
      'safetyBoundary': safetyBoundary,
    };
  }
}

class CareerRoadmapModel {
  final String roleId;
  final String title;
  final List<String> steps;
  final List<String> recommendedActivities;

  const CareerRoadmapModel({
    required this.roleId,
    required this.title,
    this.steps = const <String>[],
    this.recommendedActivities = const <String>[],
  });

  factory CareerRoadmapModel.fromJson(Map<String, dynamic> json) {
    return CareerRoadmapModel(
      roleId: _readString(json['roleId']),
      title: _readString(json['title'], 'Career Roadmap'),
      steps: _readStringList(json['steps']),
      recommendedActivities: _readStringList(json['recommendedActivities']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roleId': roleId,
      'title': title,
      'steps': steps,
      'recommendedActivities': recommendedActivities,
    };
  }
}

class UserSkillProfileModel {
  final List<String> topStrengths;
  final List<String> weakAreas;
  final Map<String, int> skillScores;
  final List<String> preferredRoles;
  final int completedChapters;
  final int completedActivities;
  final int failedMiniGames;
  final DateTime? updatedAt;

  const UserSkillProfileModel({
    this.topStrengths = const <String>[],
    this.weakAreas = const <String>[],
    this.skillScores = const <String, int>{},
    this.preferredRoles = const <String>[],
    this.completedChapters = 0,
    this.completedActivities = 0,
    this.failedMiniGames = 0,
    this.updatedAt,
  });

  static const empty = UserSkillProfileModel();

  factory UserSkillProfileModel.fromJson(Map<String, dynamic> json) {
    return UserSkillProfileModel(
      topStrengths: _readStringList(json['topStrengths']),
      weakAreas: _readStringList(json['weakAreas']),
      skillScores: _readIntMap(json['skillScores']),
      preferredRoles: _readStringList(json['preferredRoles']),
      completedChapters: _readNonNegativeInt(json['completedChapters']),
      completedActivities: _readNonNegativeInt(json['completedActivities']),
      failedMiniGames: _readNonNegativeInt(json['failedMiniGames']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  factory UserSkillProfileModel.fromScore({
    required ScoreModel score,
    List<String> preferredRoles = const <String>[],
    int completedChapters = 0,
    int completedActivities = 0,
    int failedMiniGames = 0,
  }) {
    final scores = <String, int>{
      'skill': score.skill,
      'discipline': score.discipline,
      'ethics': score.ethics,
      'communication': score.communication,
      'chaos_control': -score.chaos,
    };
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final weak = scores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return UserSkillProfileModel(
      topStrengths: ranked.map((entry) => entry.key).take(3).toList(growable: false),
      weakAreas: weak.map((entry) => entry.key).take(3).toList(growable: false),
      skillScores: scores,
      preferredRoles: preferredRoles.take(3).toList(growable: false),
      completedChapters: completedChapters,
      completedActivities: completedActivities,
      failedMiniGames: failedMiniGames,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'topStrengths': topStrengths,
      'weakAreas': weakAreas,
      'skillScores': skillScores,
      'preferredRoles': preferredRoles,
      'completedChapters': completedChapters,
      'completedActivities': completedActivities,
      'failedMiniGames': failedMiniGames,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class WeeklyLearningPlanModel {
  final String title;
  final List<String> focusAreas;
  final List<String> dailySteps;
  final String nextRoleId;
  final String nextChapterId;
  final String nextActivityId;
  final List<String> roadmapSuggestions;
  final String safetyNote;
  final DateTime? generatedAt;

  const WeeklyLearningPlanModel({
    this.title = 'Weekly Career Chaos Plan',
    this.focusAreas = const <String>[],
    this.dailySteps = const <String>[],
    this.nextRoleId = '',
    this.nextChapterId = '',
    this.nextActivityId = '',
    this.roadmapSuggestions = const <String>[],
    this.safetyNote = '',
    this.generatedAt,
  });

  static const empty = WeeklyLearningPlanModel();

  factory WeeklyLearningPlanModel.fromJson(Map<String, dynamic> json) {
    return WeeklyLearningPlanModel(
      title: _readString(json['title'], 'Weekly Career Chaos Plan'),
      focusAreas: _readStringList(json['focusAreas']),
      dailySteps: _readStringList(json['dailySteps']),
      nextRoleId: _readString(json['nextRoleId']),
      nextChapterId: _readString(json['nextChapterId']),
      nextActivityId: _readString(json['nextActivityId']),
      roadmapSuggestions: _readStringList(json['roadmapSuggestions']),
      safetyNote: _readString(json['safetyNote']),
      generatedAt: _readDate(json['generatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'focusAreas': focusAreas,
      'dailySteps': dailySteps,
      'nextRoleId': nextRoleId,
      'nextChapterId': nextChapterId,
      'nextActivityId': nextActivityId,
      'roadmapSuggestions': roadmapSuggestions,
      'safetyNote': safetyNote,
      'generatedAt': generatedAt?.toIso8601String(),
    };
  }
}

class CareerCoachPreferenceModel {
  final String selectedStyleId;
  final bool roastModeEnabled;

  const CareerCoachPreferenceModel({
    this.selectedStyleId = 'calm_teacher',
    this.roastModeEnabled = false,
  });

  static const defaults = CareerCoachPreferenceModel();

  factory CareerCoachPreferenceModel.fromJson(Map<String, dynamic> json) {
    return CareerCoachPreferenceModel(
      selectedStyleId: _readString(json['selectedStyleId'], 'calm_teacher'),
      roastModeEnabled: json['roastModeEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'selectedStyleId': selectedStyleId,
      'roastModeEnabled': roastModeEnabled,
    };
  }

  CareerCoachPreferenceModel copyWith({
    String? selectedStyleId,
    bool? roastModeEnabled,
  }) {
    return CareerCoachPreferenceModel(
      selectedStyleId: selectedStyleId ?? this.selectedStyleId,
      roastModeEnabled: roastModeEnabled ?? this.roastModeEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CareerCoachPreferenceModel &&
        other.selectedStyleId == selectedStyleId &&
        other.roastModeEnabled == roastModeEnabled;
  }

  @override
  int get hashCode => Object.hash(selectedStyleId, roastModeEnabled);
}

class CareerCoachStateModel {
  final CareerCoachPreferenceModel preference;
  final UserSkillProfileModel skillProfile;
  final WeeklyLearningPlanModel weeklyPlan;
  final String lastAdvice;
  final DateTime? updatedAt;

  const CareerCoachStateModel({
    this.preference = CareerCoachPreferenceModel.defaults,
    this.skillProfile = UserSkillProfileModel.empty,
    this.weeklyPlan = WeeklyLearningPlanModel.empty,
    this.lastAdvice = '',
    this.updatedAt,
  });

  static const defaults = CareerCoachStateModel();

  factory CareerCoachStateModel.fromJson(Map<String, dynamic> json) {
    return CareerCoachStateModel(
      preference: json['preference'] is Map<String, dynamic>
          ? CareerCoachPreferenceModel.fromJson(json['preference'] as Map<String, dynamic>)
          : CareerCoachPreferenceModel.defaults,
      skillProfile: json['skillProfile'] is Map<String, dynamic>
          ? UserSkillProfileModel.fromJson(json['skillProfile'] as Map<String, dynamic>)
          : UserSkillProfileModel.empty,
      weeklyPlan: json['weeklyPlan'] is Map<String, dynamic>
          ? WeeklyLearningPlanModel.fromJson(json['weeklyPlan'] as Map<String, dynamic>)
          : WeeklyLearningPlanModel.empty,
      lastAdvice: _readString(json['lastAdvice']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'preference': preference.toJson(),
      'skillProfile': skillProfile.toJson(),
      'weeklyPlan': weeklyPlan.toJson(),
      'lastAdvice': lastAdvice,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  CareerCoachStateModel copyWith({
    CareerCoachPreferenceModel? preference,
    UserSkillProfileModel? skillProfile,
    WeeklyLearningPlanModel? weeklyPlan,
    String? lastAdvice,
    DateTime? updatedAt,
  }) {
    return CareerCoachStateModel(
      preference: preference ?? this.preference,
      skillProfile: skillProfile ?? this.skillProfile,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      lastAdvice: lastAdvice ?? this.lastAdvice,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String _readString(Object? value, [String fallback = '']) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
}

Map<String, int> _readIntMap(Object? value) {
  if (value is! Map) return const <String, int>{};
  final result = <String, int>{};
  value.forEach((key, item) {
    if (key is String && item is num) result[key] = item.toInt();
  });
  return Map<String, int>.unmodifiable(result);
}

int _readNonNegativeInt(Object? value) {
  if (value is int && value >= 0) return value;
  if (value is num && value >= 0) return value.toInt();
  return 0;
}

DateTime? _readDate(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
