import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/activity_model.dart';
import '../models/career_coach/user_skill_profile_model.dart';
import '../models/progress_snapshot_model.dart';
import '../models/role_progress_model.dart';
import '../models/role_scenario_model.dart';
import '../models/score_model.dart';
import 'progress_service.dart';
import 'scenario_service.dart';
import 'skill_tree_service.dart';

class CareerCoachService {
  CareerCoachService._();

  static final CareerCoachService instance = CareerCoachService._();

  static const _coachStylesPath = 'assets/game/career_coach/coach_styles.json';
  static const _careerRoadmapsPath = 'assets/game/career_coach/career_roadmaps.json';

  List<CoachMentorStyleModel>? _cachedStyles;
  List<CareerRoadmapModel>? _cachedRoadmaps;

  Future<List<CoachMentorStyleModel>> loadCoachStyles() async {
    if (_cachedStyles != null) return _cachedStyles!;
    try {
      final raw = await rootBundle.loadString(_coachStylesPath);
      final json = jsonDecode(raw);
      final list = json is Map<String, dynamic> ? json['styles'] : null;
      if (list is List) {
        _cachedStyles = list
            .whereType<Map<String, dynamic>>()
            .map(CoachMentorStyleModel.fromJson)
            .where((style) => style.id.isNotEmpty)
            .toList(growable: false);
      }
    } on Object {
      _cachedStyles = const <CoachMentorStyleModel>[];
    }
    if (_cachedStyles == null || _cachedStyles!.isEmpty) {
      _cachedStyles = const <CoachMentorStyleModel>[
        CoachMentorStyleModel(
          id: 'calm_teacher',
          name: 'Calm Teacher',
          tone: 'patient_explainer',
          encouragement: 'One better decision at a time is still progress.',
          safetyBoundary: 'Keep advice educational and safe.',
        ),
      ];
    }
    return _cachedStyles!;
  }

  Future<List<CareerRoadmapModel>> loadCareerRoadmaps() async {
    if (_cachedRoadmaps != null) return _cachedRoadmaps!;
    try {
      final raw = await rootBundle.loadString(_careerRoadmapsPath);
      final json = jsonDecode(raw);
      final list = json is Map<String, dynamic> ? json['roadmaps'] : null;
      if (list is List) {
        _cachedRoadmaps = list
            .whereType<Map<String, dynamic>>()
            .map(CareerRoadmapModel.fromJson)
            .where((roadmap) => roadmap.roleId.isNotEmpty)
            .toList(growable: false);
      }
    } on Object {
      _cachedRoadmaps = const <CareerRoadmapModel>[];
    }
    _cachedRoadmaps ??= const <CareerRoadmapModel>[];
    return _cachedRoadmaps!;
  }

  Future<CoachMentorStyleModel> selectedStyle() async {
    final styles = await loadCoachStyles();
    final selectedId = ProgressService.instance.careerCoachState.value.preference.selectedStyleId;
    return styles.firstWhere(
      (style) => style.id == selectedId,
      orElse: () => styles.first,
    );
  }

  UserSkillProfileModel analyzeUserSkillProfile(ProgressSnapshotModel snapshot) {
    final roleCompletions = <String, int>{};
    var completedChapters = 0;
    snapshot.progressByRole.forEach((roleId, progress) {
      final count = progress.completedChapterIds.length;
      if (count > 0) roleCompletions[roleId] = count;
      completedChapters += count;
    });

    final preferred = roleCompletions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final failedMiniGames = snapshot.progressByRole.values.fold<int>(
      0,
      (total, progress) => total + progress.miniGameResults.values.where((item) => !item.isSuccess).length,
    ) + snapshot.flameMiniGameHistory.where((item) => !item.isSuccess).length;

    return UserSkillProfileModel.fromScore(
      score: snapshot.totalScore,
      preferredRoles: preferred.map((entry) => entry.key).toList(growable: false),
      completedChapters: completedChapters,
      completedActivities: snapshot.activityHistory.length,
      failedMiniGames: failedMiniGames,
    );
  }

  List<String> topStrengths(UserSkillProfileModel profile) {
    final strengths = profile.topStrengths.where((item) => item.trim().isNotEmpty).toList(growable: false);
    if (strengths.length >= 3) return strengths.take(3).toList(growable: false);
    final fallback = <String>['learning consistency', 'career curiosity', 'scenario reflection'];
    return <String>{...strengths, ...fallback}.take(3).toList(growable: false);
  }

  List<String> weakAreas(UserSkillProfileModel profile) {
    final weak = profile.weakAreas.where((item) => item.trim().isNotEmpty).toList(growable: false);
    if (weak.length >= 3) return weak.take(3).toList(growable: false);
    final fallback = <String>['discipline', 'communication', 'chaos_control'];
    return <String>{...weak, ...fallback}.take(3).toList(growable: false);
  }


  Future<List<String>> weakSkillNodeRecommendations({
    required ProgressSnapshotModel snapshot,
    String? roleId,
  }) async {
    final targetRole = roleId ??
        (snapshot.progressByRole.isNotEmpty
            ? snapshot.progressByRole.keys.first
            : 'developer');
    final nodes = await SkillTreeService.instance.weakUnlockedSkillNodes(
      snapshot: snapshot,
      roleId: targetRole,
    );
    if (nodes.isEmpty) {
      return const <String>['Start with the first unlocked skill node in your preferred role.'];
    }
    return nodes
        .map((node) => 'Practice ${node.title} with linked chapters or mini-games.')
        .toList(growable: false);
  }

  String suggestNextActivity(UserSkillProfileModel profile) {
    final weak = weakAreas(profile);
    if (weak.contains('communication')) return 'client_negotiation_one_small_change';
    if (weak.contains('ethics')) return 'ethical_dilemma_red_flag_rush';
    if (weak.contains('discipline')) return 'daily_chaos_triage';
    if (weak.contains('skill')) return 'bug_hunt_login_safari';
    if (weak.contains('chaos_control')) return 'data_cleanup_race';
    return 'daily_chaos_triage';
  }

  Future<String> suggestNextRole({
    required ProgressSnapshotModel snapshot,
    List<RoleScenarioModel> roles = const <RoleScenarioModel>[],
  }) async {
    if (roles.isEmpty) return '';
    final sorted = roles.toList(growable: false)
      ..sort((a, b) {
        final aCompleted = snapshot.progressByRole[a.role.id]?.completedChapterIds.length ?? 0;
        final bCompleted = snapshot.progressByRole[b.role.id]?.completedChapterIds.length ?? 0;
        return aCompleted.compareTo(bCompleted);
      });
    return sorted.first.role.id;
  }

  String suggestNextChapter({
    required ProgressSnapshotModel snapshot,
    required RoleScenarioModel roleScenario,
  }) {
    final progress = snapshot.progressByRole[roleScenario.role.id] ?? RoleProgressModel(roleId: roleScenario.role.id);
    for (final chapter in roleScenario.chapters) {
      if (!progress.completedChapterIds.contains(chapter.id) && !chapter.isCleanupMission) {
        return chapter.id;
      }
    }
    return roleScenario.chapters.isEmpty ? '' : roleScenario.chapters.last.id;
  }

  Future<WeeklyLearningPlanModel> generateWeeklyLearningPlan({
    required ProgressSnapshotModel snapshot,
    List<RoleScenarioModel> roles = const <RoleScenarioModel>[],
  }) async {
    final profile = analyzeUserSkillProfile(snapshot);
    final weak = weakAreas(profile);
    final roadmaps = await loadCareerRoadmaps();
    final nextRoleId = await suggestNextRole(snapshot: snapshot, roles: roles);
    RoleScenarioModel? nextRole;
    for (final role in roles) {
      if (role.role.id == nextRoleId) {
        nextRole = role;
        break;
      }
    }
    final preferredRoadmap = roadmaps.firstWhere(
      (roadmap) => roadmap.roleId == (nextRole?.role.id ?? profile.preferredRoles.firstOrNull ?? ''),
      orElse: () => roadmaps.isNotEmpty ? roadmaps.first : const CareerRoadmapModel(roleId: '', title: 'Career Roadmap'),
    );
    return WeeklyLearningPlanModel(
      title: '7-Day ${_humanize(weak.first)} Improvement Plan',
      focusAreas: weak,
      dailySteps: <String>[
        'Day 1: Replay one chapter and explain the safest choice in one sentence.',
        'Day 2: Complete the suggested activity: ${suggestNextActivity(profile)}.',
        'Day 3: Review one glossary term from your preferred role.',
        'Day 4: Practice a mini-game and focus on ${_humanize(weak.first)}.',
        'Day 5: Open the role dashboard and review mentor feedback.',
        'Day 6: Try a chapter without choosing the obvious shortcut.',
        'Day 7: Compare your score trend and repeat the weakest area activity.',
      ],
      nextRoleId: nextRole?.role.id ?? '',
      nextChapterId: nextRole == null ? '' : suggestNextChapter(snapshot: snapshot, roleScenario: nextRole),
      nextActivityId: suggestNextActivity(profile),
      roadmapSuggestions: preferredRoadmap.steps,
      safetyNote: safetyFilter('This is educational coaching. For medical, legal, financial, HR, or engineering decisions, follow qualified professional guidance and workplace policy.'),
      generatedAt: DateTime.now(),
    );
  }

  Future<String> generateCoachAdvice({
    required ProgressSnapshotModel snapshot,
    List<RoleScenarioModel> roles = const <RoleScenarioModel>[],
  }) async {
    final profile = analyzeUserSkillProfile(snapshot);
    final style = await selectedStyle();
    final strengths = topStrengths(profile);
    final weak = weakAreas(profile);
    final plan = await generateWeeklyLearningPlan(snapshot: snapshot, roles: roles);
    final preference = ProgressService.instance.careerCoachState.value.preference;
    final roast = preference.roastModeEnabled && style.id == 'roast_mentor'
        ? 'Roast mode: Your shortcut energy has startup-founder confidence and intern-level documentation. Fix the documentation, keep the confidence.'
        : '';
    final advice = <String>[
      '${style.name}: ${style.encouragement}',
      'Top strengths: ${strengths.map(_humanize).join(', ')}.',
      'Top weak areas: ${weak.map(_humanize).join(', ')}.',
      'Next activity: ${plan.nextActivityId}.',
      ...(await weakSkillNodeRecommendations(snapshot: snapshot)).take(2),
      if (plan.nextRoleId.isNotEmpty) 'Next role focus: ${_humanize(plan.nextRoleId)}.',
      if (roast.isNotEmpty) roast,
      plan.safetyNote,
    ].join('\n\n');
    return safetyFilter(advice);
  }

  String safetyFilter(String input) {
    var text = input.trim();
    const blocked = <String, String>{
      'stupid': 'risky',
      'idiot': 'risky',
      'worthless': 'risky',
      'useless': 'needs practice',
      'dumb': 'risky',
      'prescribe': 'recommend professional evaluation for',
      'dosage': 'safe escalation',
      'guaranteed return': 'uncertain outcome',
      'ignore safety': 'escalate safety',
    };
    blocked.forEach((bad, safe) {
      text = text.replaceAll(RegExp(bad, caseSensitive: false), safe);
    });
    return text;
  }

  Future<CareerCoachStateModel> refreshAndSaveCoachState({
    List<RoleScenarioModel> roles = const <RoleScenarioModel>[],
  }) async {
    final snapshot = ProgressService.instance.currentSnapshot();
    final profile = analyzeUserSkillProfile(snapshot);
    final plan = await generateWeeklyLearningPlan(snapshot: snapshot, roles: roles);
    final advice = await generateCoachAdvice(snapshot: snapshot, roles: roles);
    final current = ProgressService.instance.careerCoachState.value;
    final updated = current.copyWith(
      skillProfile: profile,
      weeklyPlan: plan,
      lastAdvice: advice,
      updatedAt: DateTime.now(),
    );
    await ProgressService.instance.updateCareerCoachState(updated);
    return updated;
  }

  String _humanize(String value) {
    return value.replaceAll('_', ' ').trim();
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
