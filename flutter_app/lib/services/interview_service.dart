import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/interview_question_model.dart';
import 'api_client.dart';

class InterviewQuestionBankResult {
  final List<InterviewQuestionModel> questions;
  final Map<String, String> rubric;

  const InterviewQuestionBankResult({
    required this.questions,
    required this.rubric,
  });
}

class InterviewService {
  InterviewService._();

  static final InterviewService instance = InterviewService._();
  static const String _assetPath = 'assets/game/interview/question_banks.json';
  static const String _localReportsKey = 'career_chaos_interview_reports_v1';

  Future<InterviewQuestionBankResult> loadQuestionsForRole(String roleId) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/interview/questions/${Uri.encodeComponent(roleId)}');
        return _bankFromJson(json, filterRoleId: roleId);
      } on Object {
        // Keep the mode available offline and during local development.
      }
    }
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const InterviewServiceException('Interview question bank is invalid.');
    }
    return _bankFromJson(decoded, filterRoleId: roleId);
  }

  Future<InterviewAnswerFeedbackModel> generateFeedback({
    required InterviewQuestionModel question,
    required String answer,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/interview/feedback', <String, dynamic>{
          'question': question.toJson(),
          'answer': answer,
        });
        return InterviewAnswerFeedbackModel.fromJson(json);
      } on Object {
        // Fallback to bundled feedback engine.
      }
    }
    return _localFeedback(question: question, answer: answer);
  }

  Future<InterviewReadinessReportModel> saveReport(InterviewReadinessReportModel report) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/users/${Uri.encodeComponent(report.userId)}/interview-reports',
          report.toJson(),
        );
        return InterviewReadinessReportModel.fromJson(json);
      } on Object {
        // Fallback to local report saving.
      }
    }
    final reports = await loadSavedReports(report.userId);
    final updated = <InterviewReadinessReportModel>[report, ...reports].take(20).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localReportsKey,
      jsonEncode(updated.map((item) => item.toJson()).toList(growable: false)),
    );
    return report;
  }

  Future<List<InterviewReadinessReportModel>> loadSavedReports(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localReportsKey);
    if (raw == null || raw.trim().isEmpty) return const <InterviewReadinessReportModel>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <InterviewReadinessReportModel>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(InterviewReadinessReportModel.fromJson)
        .where((report) => report.userId == userId)
        .toList(growable: false);
  }

  InterviewReadinessReportModel buildReport({
    required String userId,
    required String roleId,
    required String roleName,
    required List<InterviewAnswerFeedbackModel> feedbackItems,
  }) {
    final now = DateTime.now().toIso8601String();
    final totalScore = feedbackItems.isEmpty
        ? 0
        : (feedbackItems.map((item) => item.score).reduce((a, b) => a + b) / feedbackItems.length).round();
    final strengths = feedbackItems
        .expand((item) => item.strengths)
        .toSet()
        .take(5)
        .toList(growable: false);
    final improvementAreas = feedbackItems
        .expand((item) => item.improvementTips)
        .toSet()
        .take(6)
        .toList(growable: false);
    final nextSteps = <String>[
      if (totalScore < 60) 'Retry the weakest round and answer in STAR format: Situation, Task, Action, Result.',
      if (totalScore >= 60 && totalScore < 80) 'Add stronger evidence, metrics, and role-specific vocabulary in the next attempt.',
      if (totalScore >= 80) 'Practice a harder mock round and keep answers concise under time pressure.',
      'Connect answers with mini-game lessons and scenario consequences from the normal game mode.',
    ];
    return InterviewReadinessReportModel(
      id: 'interview_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      roleId: roleId,
      roleName: roleName,
      totalScore: totalScore,
      readinessLevel: _readinessLevel(totalScore),
      feedbackItems: feedbackItems,
      strengths: strengths,
      improvementAreas: improvementAreas,
      nextSteps: nextSteps,
      savedAt: now,
    );
  }

  InterviewQuestionBankResult _bankFromJson(Map<String, dynamic> json, {required String filterRoleId}) {
    final rawRubric = json['rubric'];
    final rubric = <String, String>{};
    if (rawRubric is Map) {
      rawRubric.forEach((key, value) {
        if (key is String && value is String) rubric[key] = value;
      });
    }
    final rawQuestions = json['questions'];
    if (rawQuestions is! List) {
      throw const InterviewServiceException('No interview questions found.');
    }
    final questions = rawQuestions
        .whereType<Map<String, dynamic>>()
        .map(InterviewQuestionModel.fromJson)
        .where((question) => question.roleId == filterRoleId)
        .toList(growable: false);
    if (questions.isEmpty) {
      throw InterviewServiceException('No interview question bank found for $filterRoleId.');
    }
    return InterviewQuestionBankResult(
      questions: questions,
      rubric: Map<String, String>.unmodifiable(rubric),
    );
  }

  InterviewAnswerFeedbackModel _localFeedback({
    required InterviewQuestionModel question,
    required String answer,
  }) {
    final normalized = answer.toLowerCase();
    final words = normalized.split(RegExp(r'\s+')).where((item) => item.trim().isNotEmpty).toSet();
    final matchedKeywords = question.expectedKeywords
        .where((keyword) => normalized.contains(keyword.toLowerCase()))
        .toList(growable: false);
    final missingKeywords = question.expectedKeywords
        .where((keyword) => !matchedKeywords.contains(keyword))
        .take(5)
        .toList(growable: false);
    final structureBonus = _containsAny(normalized, const ['first', 'then', 'because', 'after', 'finally', 'result', 'impact']) ? 12 : 4;
    final evidenceBonus = _containsAny(normalized, const ['log', 'metric', 'data', 'evidence', 'document', 'steps', 'test', 'review']) ? 14 : 5;
    final ethicsBonus = _containsAny(normalized, const ['safe', 'risk', 'ethic', 'policy', 'compliance', 'fair', 'patient', 'privacy']) ? 18 : 8;
    final communicationBonus = _containsAny(normalized, const ['communicate', 'stakeholder', 'client', 'team', 'manager', 'explain', 'align']) ? 15 : 7;
    final knowledgeBonus = min(25, matchedKeywords.length * 4 + (words.length >= 35 ? 7 : 2));
    final rubricScores = <String, int>{
      'clarity': min(20, structureBonus + (words.length >= 25 ? 6 : 0)),
      'roleKnowledge': knowledgeBonus,
      'evidence': min(20, evidenceBonus),
      'communication': min(15, communicationBonus),
      'ethics': min(20, ethicsBonus),
    };
    final score = rubricScores.values.fold<int>(0, (sum, item) => sum + item).clamp(0, 100).toInt();
    final strengths = <String>[
      if (rubricScores['clarity']! >= 14) 'Clear answer structure',
      if (rubricScores['roleKnowledge']! >= 16) 'Good role-specific thinking',
      if (rubricScores['evidence']! >= 14) 'Uses evidence or verification',
      if (rubricScores['communication']! >= 12) 'Stakeholder-aware communication',
      if (rubricScores['ethics']! >= 15) 'Strong safety and ethics awareness',
      if (matchedKeywords.isNotEmpty) 'Covered key terms: ${matchedKeywords.take(3).join(', ')}',
    ];
    final tips = <String>[
      if (answer.trim().split(RegExp(r'\s+')).length < 35) 'Expand the answer with a concrete example, action, and result.',
      if (missingKeywords.isNotEmpty) 'Include missing role keywords: ${missingKeywords.join(', ')}.',
      if (rubricScores['evidence']! < 12) 'Add proof: logs, test cases, patient notes, site records, metrics, or documented constraints.',
      if (rubricScores['communication']! < 10) 'Mention who you would inform and how you would align the team/client/stakeholder.',
      if (rubricScores['ethics']! < 14) 'Call out safety, fairness, policy, privacy, or professional boundaries explicitly.',
    ];
    return InterviewAnswerFeedbackModel(
      questionId: question.id,
      answer: answer,
      score: score,
      rubricScores: rubricScores,
      strengths: strengths.isEmpty ? const <String>['You attempted the question and can now improve it.'] : strengths,
      improvementTips: tips.isEmpty ? const <String>['Good attempt. Retry with tighter structure and one measurable result.'] : tips,
      matchedKeywords: matchedKeywords,
      missingKeywords: missingKeywords,
      aiSummary: _summaryForScore(score),
      retryPrompt: 'Retry this answer in 60–90 seconds using STAR format and include: ${missingKeywords.take(3).join(', ')}.',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  bool _containsAny(String text, List<String> needles) {
    return needles.any((needle) => text.contains(needle));
  }

  String _summaryForScore(int score) {
    if (score >= 80) return 'AI feedback: Interview-ready answer with strong professional signals.';
    if (score >= 60) return 'AI feedback: Good base answer. Add proof, trade-offs, and concise structure.';
    return 'AI feedback: Needs more structure, role-specific process, and safety-aware reasoning.';
  }

  String _readinessLevel(int score) {
    if (score >= 85) return 'Interview Ready';
    if (score >= 70) return 'Almost Ready';
    if (score >= 50) return 'Needs Practice';
    return 'Foundation Required';
  }
}

class InterviewServiceException implements Exception {
  final String message;
  const InterviewServiceException(this.message);

  @override
  String toString() => message;
}
