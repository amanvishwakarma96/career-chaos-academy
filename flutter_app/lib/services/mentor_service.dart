import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/activity_model.dart';
import '../models/choice_model.dart';
import '../models/mentor/mentor_model.dart';
import '../models/progress_snapshot_model.dart';
import '../models/progress_update_result_model.dart';
import '../models/role_scenario_model.dart';
import '../models/scenario_model.dart';
import '../models/score_model.dart';
import 'progress_service.dart';

class MentorService {
  MentorService._();

  static final MentorService instance = MentorService._();

  static const String _assetPath = 'assets/game/mentors/mentors.json';

  List<MentorModel>? _cachedMentors;

  Future<List<MentorModel>> loadMentors() async {
    if (_cachedMentors != null) {
      return _cachedMentors!;
    }
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw);
      final list = json is Map<String, dynamic> ? json['mentors'] : null;
      if (list is List) {
        _cachedMentors = list
            .whereType<Map<String, dynamic>>()
            .map(MentorModel.fromJson)
            .where((mentor) => mentor.id.isNotEmpty && mentor.name.isNotEmpty)
            .toList(growable: false);
      }
    } on Object {
      _cachedMentors = const <MentorModel>[];
    }
    if (_cachedMentors == null || _cachedMentors!.isEmpty) {
      _cachedMentors = const <MentorModel>[
        MentorModel(
          id: 'balanced_coach',
          name: 'Maya',
          title: 'Balanced Career Coach',
          style: 'supportive_balanced',
          description: 'Safe, supportive, practical guidance.',
          archetype: 'mentor',
          emoji: '🧭',
        ),
      ];
    }
    return _cachedMentors!;
  }

  Future<MentorModel> selectedMentor() async {
    final mentors = await loadMentors();
    final selectedId = ProgressService.instance.mentorPreference.value.selectedMentorId;
    return mentors.firstWhere(
      (mentor) => mentor.id == selectedId,
      orElse: () => mentors.first,
    );
  }

  List<String> detectWeakAreas(ScoreModel score) {
    final weakAreas = <String>[];
    if (score.discipline <= 0) weakAreas.add('discipline');
    if (score.communication <= 0) weakAreas.add('communication');
    if (score.ethics <= 0) weakAreas.add('ethics');
    if (score.skill <= 0) weakAreas.add('skill');
    if (score.chaos > 0) weakAreas.add('chaos control');
    return weakAreas;
  }

  String suggestNextActivity(List<String> weakAreas) {
    if (weakAreas.contains('communication')) {
      return 'Try Client Negotiation or Ethical Feedback Quiz to practice calm communication.';
    }
    if (weakAreas.contains('ethics')) {
      return 'Try Ethical Dilemma to practice safe, principled decisions.';
    }
    if (weakAreas.contains('discipline')) {
      return 'Try Daily Chaos Triage to practice process discipline under pressure.';
    }
    if (weakAreas.contains('skill')) {
      return 'Try Bug Hunt Room or a role mini-game to sharpen technical judgment.';
    }
    if (weakAreas.contains('chaos control')) {
      return 'Try Data Cleanup Race to convert chaos into clean, repeatable steps.';
    }
    return 'Continue the next story chapter or replay an activity for mastery.';
  }

  Future<MentorFeedbackModel> feedbackAfterChapter({
    required RoleScenarioModel roleScenario,
    required ScenarioModel scenario,
    required ChoiceModel choice,
    required ProgressUpdateResultModel progressUpdate,
  }) async {
    final mentor = await selectedMentor();
    final weakAreas = detectWeakAreas(choice.scoreImpact);
    final strengths = _detectStrengths(choice.scoreImpact);
    final roastEnabled = ProgressService.instance.mentorPreference.value.roastModeEnabled;
    final stylePrefix = _stylePrefix(mentor.style);
    final professionalContext = scenario.learningObjective.isNotEmpty
        ? 'Objective: ${scenario.learningObjective}'
        : 'Focus on the professional principle behind this decision.';
    final choiceTone = choice.scoreImpact.chaos > 0
        ? 'This choice created avoidable chaos. The next improvement is to slow down, document, and choose a safer path.'
        : 'This choice protected the workflow. Keep repeating the evidence-first habit.';
    final weakLine = weakAreas.isEmpty
        ? 'No major weak area showed up in this decision.'
        : 'Weak area to practice: ${weakAreas.join(', ')}.';
    final strengthLine = strengths.isEmpty
        ? 'Strength observed: willingness to learn from the outcome.'
        : 'Strength observed: ${strengths.join(', ')}.';
    final feedback = [
      stylePrefix,
      professionalContext,
      strengthLine,
      weakLine,
      choiceTone,
      if (scenario.safetyGuardrails.isNotEmpty)
        'Safety guardrail: ${scenario.safetyGuardrails.first}',
    ].where((item) => item.trim().isNotEmpty).join('\n\n');

    return MentorFeedbackModel(
      mentor: mentor,
      headline: '${mentor.emoji} ${mentor.name} says:',
      feedback: _sanitizeFeedback(feedback),
      weakAreas: weakAreas,
      nextActivitySuggestion: suggestNextActivity(weakAreas),
      weeklySummary: weeklyProgressSummary(
        ProgressService.instance.currentSnapshot(),
      ),
      roastLine: roastEnabled ? _safeRoast(mentor, choice.scoreImpact) : null,
      safetyNote: _safetyNoteForScenario(scenario),
    );
  }

  String weeklyProgressSummary(ProgressSnapshotModel snapshot) {
    final weakAreas = detectWeakAreas(snapshot.totalScore);
    final completedChapters = snapshot.progressByRole.values.fold<int>(
      0,
      (total, progress) => total + progress.completedChapterIds.length,
    );
    final activities = snapshot.activityHistory.length;
    final rankLine = 'You have ${snapshot.totalXp} XP from story, activity, and mini-game progress.';
    final chapterLine = 'Completed chapters: $completedChapters. Activities attempted: $activities.';
    final weakLine = weakAreas.isEmpty
        ? 'Current profile is balanced. Keep building consistency.'
        : 'This week, practice: ${weakAreas.join(', ')}.';
    return '$rankLine\n$chapterLine\n$weakLine';
  }

  List<String> _detectStrengths(ScoreModel score) {
    final strengths = <String>[];
    if (score.skill > 0) strengths.add('skill');
    if (score.discipline > 0) strengths.add('discipline');
    if (score.ethics > 0) strengths.add('ethics');
    if (score.communication > 0) strengths.add('communication');
    if (score.chaos <= 0) strengths.add('chaos control');
    return strengths;
  }

  String _stylePrefix(String style) {
    switch (style) {
      case 'direct_process_first':
        return 'Direct review: the process matters because future you depends on present you.';
      case 'humorous_gentle':
        return 'Friendly chaos check: we can laugh, but we still learn.';
      case 'empathetic_safety_first':
        return 'Safety-first reflection: protect people, trust, and evidence before speed.';
      default:
        return 'Balanced reflection: good careers are built through repeatable decisions.';
    }
  }

  String _safeRoast(MentorModel mentor, ScoreModel score) {
    final source = mentor.roastLines.isNotEmpty
        ? mentor.roastLines
        : const <String>[
            'That decision had dramatic music, but the process asked for a helmet.',
          ];
    final index = (score.total.abs() + score.chaos.abs()) % source.length;
    return _sanitizeFeedback(source[index]);
  }

  String _safetyNoteForScenario(ScenarioModel scenario) {
    final role = scenario.role.name.toLowerCase();
    if (role.contains('doctor')) {
      return 'Safety note: this game teaches triage communication and escalation only. It does not diagnose, prescribe, or give dosage guidance.';
    }
    if (role.contains('engineer') || role.contains('civil')) {
      return 'Safety note: unsafe site or material concerns should be inspected, documented, and escalated to qualified professionals.';
    }
    if (role.contains('hr')) {
      return 'Safety note: use structured, role-related evidence and avoid biased or discriminatory feedback.';
    }
    if (role.contains('back office')) {
      return 'Safety note: protect personal data and keep an audit trail when handling records.';
    }
    return 'Safety note: mentor feedback is educational, supportive, and should not replace real workplace policy or expert guidance.';
  }

  String _sanitizeFeedback(String text) {
    const banned = <String>['stupid', 'idiot', 'worthless', 'useless', 'dumb'];
    var result = text;
    for (final word in banned) {
      result = result.replaceAll(RegExp(word, caseSensitive: false), 'risky');
    }
    return result.trim();
  }
}
