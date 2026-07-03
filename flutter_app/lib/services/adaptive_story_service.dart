import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/adaptive/adaptive_story_model.dart';
import '../models/adaptive/user_behavior_summary_model.dart';
import '../models/dialogue_line_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../models/score_model.dart';
import 'future_scope/feature_flag_service.dart';
import 'progress_service.dart';

class AdaptiveStoryService {
  AdaptiveStoryService._();

  static final AdaptiveStoryService instance = AdaptiveStoryService._();

  bool get isEnabled =>
      FeatureFlagService.instance.isEnabled('adaptive_story_engine');

  UserBehaviorSummaryModel buildBehaviorSummary({
    required List<RoleScenarioModel> roleScenarios,
  }) {
    if (!isEnabled) return UserBehaviorSummaryModel.empty;

    final progressByRole = ProgressService.instance.progressByRole.value;
    final completedByRole = <String, int>{};
    final failedMiniGamesByRole = <String, int>{};
    var shortcutChoices = 0;
    var ethicalChoices = 0;
    var aggregateScore = ScoreModel.zero;

    for (final roleScenario in roleScenarios) {
      final roleId = roleScenario.role.id;
      final progress = progressByRole[roleId];
      final completedCount = progress?.completedChapterIds.length ?? 0;
      if (completedCount > 0) completedByRole[roleId] = completedCount;
      aggregateScore = aggregateScore.add(progress?.roleScore ?? ScoreModel.zero);

      final activeFlags = ProgressService.instance.activeFlagsFor(roleId);
      final storyFlags = ProgressService.instance.storyFlagsFor(roleId);
      final joinedFlags = <String>{...activeFlags, ...storyFlags};
      shortcutChoices += joinedFlags.where(_looksLikeShortcutFlag).length;
      ethicalChoices += joinedFlags.where(_looksLikeEthicalFlag).length;

      final miniGameResults = progress?.miniGameResults.values ?? const [];
      final failures = miniGameResults.where((item) => !item.isSuccess).length;
      if (failures > 0) failedMiniGamesByRole[roleId] = failures;
    }

    final flameFailures = ProgressService.instance.flameMiniGameHistory.value
        .where((item) => !item.isSuccess)
        .length;
    if (flameFailures > 0) {
      failedMiniGamesByRole['flame_minigames'] =
          (failedMiniGamesByRole['flame_minigames'] ?? 0) + flameFailures;
    }

    return UserBehaviorSummaryModel.fromScore(
      score: aggregateScore,
      completedChaptersByRole: completedByRole,
      failedMiniGamesByRole: failedMiniGamesByRole,
      shortcutChoiceCount: shortcutChoices,
      ethicalChoiceCount: ethicalChoices,
    );
  }

  AdaptiveStoryRecommendationModel recommendNextStory({
    required List<RoleScenarioModel> roleScenarios,
    UserBehaviorSummaryModel? summary,
  }) {
    final behavior = summary ?? buildBehaviorSummary(roleScenarios: roleScenarios);
    final preferredRole = behavior.preferredRoles.isNotEmpty
        ? behavior.preferredRoles.first
        : (roleScenarios.isNotEmpty ? roleScenarios.first.role.id : 'developer');
    final roleScenario = _firstRoleScenarioOrNull(
          roleScenarios.where((item) => item.role.id == preferredRole),
        ) ??
        (roleScenarios.isNotEmpty ? roleScenarios.first : null);
    final nextChapter = roleScenario == null
        ? null
        : _firstScenarioOrNull(
            roleScenario.chapters.where((chapter) {
              return !ProgressService.instance.isChapterCompleted(
                roleId: roleScenario.role.id,
                chapterId: chapter.id,
              );
            }),
          );

    if (behavior.hasPattern('shortcut_prone')) {
      return AdaptiveStoryRecommendationModel(
        roleId: preferredRole,
        chapterId: nextChapter?.id,
        reason: 'You often choose speed over evidence. Try a cleanup or documentation-heavy scenario next.',
        suggestedActivityType: 'ethical_dilemma',
        difficulty: 'guided',
        shouldGenerateSideMission: true,
      );
    }
    if (behavior.hasPattern('repeated_failures')) {
      return AdaptiveStoryRecommendationModel(
        roleId: preferredRole,
        chapterId: nextChapter?.id,
        reason: 'Repeated mini-game failures detected. A lower-pressure practice mission is recommended.',
        suggestedActivityType: 'daily_challenge',
        difficulty: 'guided',
        shouldGenerateSideMission: true,
      );
    }
    if (behavior.weakSkills.contains('communication')) {
      return AdaptiveStoryRecommendationModel(
        roleId: preferredRole,
        chapterId: nextChapter?.id,
        reason: 'Communication is a weak area, so the next mission should focus on stakeholder clarity.',
        suggestedActivityType: 'client_negotiation',
        difficulty: 'normal',
      );
    }
    if (behavior.weakSkills.contains('ethics')) {
      return AdaptiveStoryRecommendationModel(
        roleId: preferredRole,
        chapterId: nextChapter?.id,
        reason: 'Ethics needs reinforcement. Choose a dilemma that rewards safe escalation and transparency.',
        suggestedActivityType: 'ethical_dilemma',
        difficulty: 'normal',
      );
    }
    if (behavior.hasPattern('high_performer')) {
      return AdaptiveStoryRecommendationModel(
        roleId: preferredRole,
        chapterId: nextChapter?.id,
        reason: 'Your recent profile is strong. The story can safely increase ambiguity and difficulty.',
        suggestedActivityType: 'boss_battle',
        difficulty: 'advanced',
      );
    }
    return AdaptiveStoryRecommendationModel(
      roleId: preferredRole,
      chapterId: nextChapter?.id,
      reason: 'Continue the next available chapter. Adaptive engine is watching for stronger patterns.',
      suggestedActivityType: 'role_quiz',
      difficulty: 'normal',
    );
  }

  List<DialogueLineModel> adaptiveDialogueForScenario({
    required ScenarioModel scenario,
    required UserBehaviorSummaryModel summary,
  }) {
    if (!isEnabled || scenario.adaptiveDialogueInjections.isEmpty) {
      return const <DialogueLineModel>[];
    }
    final visible = scenario.adaptiveDialogueInjections
        .where((item) => item.isVisibleFor(summary))
        .map((item) => item.toDialogueLine())
        .toList(growable: false);
    return List<DialogueLineModel>.unmodifiable(visible);
  }

  String difficultyForScenario({
    required ScenarioModel scenario,
    required UserBehaviorSummaryModel summary,
  }) {
    if (!isEnabled) return scenario.adaptiveDifficulty.baseLevel;
    return scenario.adaptiveDifficulty.resolve(summary);
  }

  AdaptiveStoryDraftModel createSafeSideMissionDraft({
    required String roleId,
    required UserBehaviorSummaryModel summary,
    required AdaptiveStoryRecommendationModel recommendation,
  }) {
    final now = DateTime.now();
    final weakArea = summary.weakSkills.isNotEmpty ? summary.weakSkills.first : 'professional_judgment';
    return AdaptiveStoryDraftModel(
      id: 'adaptive_${roleId}_${now.millisecondsSinceEpoch}',
      roleId: roleId,
      title: 'Adaptive Practice: ${_titleCase(weakArea)}',
      createdAt: now,
      generatedJson: <String, dynamic>{
        'status': 'draft_pending_admin_review',
        'source': 'adaptive_story_engine',
        'roleId': roleId,
        'title': 'Adaptive Practice: ${_titleCase(weakArea)}',
        'difficulty': recommendation.difficulty,
        'theme': 'Personalized remediation',
        'learningObjective': 'Practice $weakArea using safe, evidence-based professional choices.',
        'safetyReview': {
          'status': 'pending',
          'domains': ['professional_learning'],
          'guardrails': _safetyGuardrailsForRole(roleId),
        },
        'mustNotAutoPublish': true,
        'requiresAdminReview': true,
        'professionalSafetyLimits': _safetyGuardrailsForRole(roleId),
        'promptVersion': 'adaptive_story_v1',
      },
    );
  }

  Future<String> loadSafePromptTemplate() async {
    try {
      return rootBundle.loadString('assets/config/adaptive_story_prompt_template.md');
    } catch (_) {
      return defaultSafePromptTemplate;
    }
  }

  static const String defaultSafePromptTemplate = '''
You are generating a Career Chaos Academy adaptive side mission draft.
Output valid JSON only. The draft must remain unpublished until admin review.
Use humor, but never provide unsafe medical, legal, financial, engineering, or HR advice.
For medical content: no diagnosis, prescription, dosage, or treatment instructions; use safe triage and escalation only.
For legal/financial content: no legal conclusions, guarantees, or regulated advice; encourage qualified professional review.
Include roleId, title, difficulty, scenario, choices, outcomes, moralLesson, professionalLearningPoint, scoreImpact, safetyReview, and mustNotAutoPublish=true.
''';

  bool isDraftSafeForReview(AdaptiveStoryDraftModel draft) {
    final jsonText = jsonEncode(draft.generatedJson).toLowerCase();
    final dangerous = <String>[
      'prescribe ',
      'dosage',
      'guaranteed return',
      'ignore safety',
      'hide evidence',
      'discriminate',
    ];
    final hasDangerousText = dangerous.any(jsonText.contains);
    final requiresReview = draft.generatedJson['requiresAdminReview'] == true &&
        draft.generatedJson['mustNotAutoPublish'] == true;
    return !hasDangerousText && requiresReview;
  }

  bool _looksLikeShortcutFlag(String value) {
    final text = value.toLowerCase();
    return text.contains('shortcut') ||
        text.contains('skipped') ||
        text.contains('ignored') ||
        text.contains('rushed');
  }

  bool _looksLikeEthicalFlag(String value) {
    final text = value.toLowerCase();
    return text.contains('documented') ||
        text.contains('escalated') ||
        text.contains('safe') ||
        text.contains('ethical') ||
        text.contains('transparent');
  }

  List<String> _safetyGuardrailsForRole(String roleId) {
    if (roleId == 'doctor') {
      return const <String>[
        'No diagnosis, prescription, dosage, or treatment instruction.',
        'Teach red-flag awareness and escalation to qualified care only.',
      ];
    }
    if (roleId == 'civil_engineer') {
      return const <String>[
        'Safety overrides schedule and budget pressure.',
        'Unsafe work requires inspection, documentation, and escalation.',
      ];
    }
    if (roleId == 'hr_executive') {
      return const <String>[
        'Avoid biased or discriminatory feedback.',
        'Use structured, role-related evidence.',
      ];
    }
    return const <String>[
      'Keep advice educational, safe, and professional.',
      'Do not encourage hiding risk, skipping documentation, or unsafe shortcuts.',
    ];
  }

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((item) => item.isNotEmpty)
        .map((item) => item[0].toUpperCase() + item.substring(1))
        .join(' ');
  }
}

RoleScenarioModel? _firstRoleScenarioOrNull(Iterable<RoleScenarioModel> items) {
  for (final item in items) {
    return item;
  }
  return null;
}

ScenarioModel? _firstScenarioOrNull(Iterable<ScenarioModel> items) {
  for (final item in items) {
    return item;
  }
  return null;
}
