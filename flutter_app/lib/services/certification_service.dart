import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/assessment_model.dart';
import '../models/assessment_session_model.dart';
import 'api_client.dart';

class AssessmentStartResult {
  final AssessmentSessionModel session;
  final AssessmentModel assessment;

  const AssessmentStartResult({required this.session, required this.assessment});
}

class AssessmentCompleteResult {
  final AssessmentSessionModel session;
  final AssessmentModel assessment;
  final CertificateRecordModel? certificate;

  const AssessmentCompleteResult({required this.session, required this.assessment, required this.certificate});
}

class CertificationService {
  CertificationService._();

  static final CertificationService instance = CertificationService._();
  static const String _assetPath = 'assets/game/assessments/role_assessments.json';
  static const String _localCertificatesKey = 'career_chaos_certificates_v1';

  Future<List<AssessmentModel>> loadAssessments() async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/assessments');
        return _assessmentsFromJson(json);
      } on Object {
        // Fallback to bundled assessments for offline/dev mode.
      }
    }
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const CertificationServiceException('Assessment catalog is invalid.');
    }
    return _assessmentsFromJson(decoded);
  }

  Future<AssessmentModel> loadAssessmentForRole(String roleId) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/assessments/${Uri.encodeComponent(roleId)}');
        final raw = json['assessment'];
        if (raw is Map<String, dynamic>) return AssessmentModel.fromJson(raw);
      } on Object {
        // Fallback to bundled assessment.
      }
    }
    final assessments = await loadAssessments();
    return assessments.firstWhere(
      (assessment) => assessment.roleId == roleId,
      orElse: () => throw CertificationServiceException('No final assessment found for $roleId.'),
    );
  }

  Future<AssessmentStartResult> startAssessment({
    required String userId,
    required String displayName,
    required String roleId,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/assessment-sessions', <String, dynamic>{
          'userId': userId,
          'displayName': displayName,
          'roleId': roleId,
        });
        final sessionJson = json['session'];
        final assessmentJson = json['assessment'];
        if (sessionJson is Map<String, dynamic> && assessmentJson is Map<String, dynamic>) {
          return AssessmentStartResult(
            session: AssessmentSessionModel.fromJson(sessionJson),
            assessment: AssessmentModel.fromJson(assessmentJson),
          );
        }
      } on Object {
        // Fallback to local session creation.
      }
    }
    final assessment = await loadAssessmentForRole(roleId);
    final now = DateTime.now();
    final session = AssessmentSessionModel(
      id: 'assessment_${now.microsecondsSinceEpoch}',
      userId: userId,
      displayName: displayName,
      roleId: assessment.roleId,
      roleName: assessment.roleName,
      assessmentId: assessment.id,
      status: 'in_progress',
      timeLimitSeconds: assessment.timeLimitSeconds,
      startedAt: now.toIso8601String(),
      expiresAt: now.add(Duration(seconds: assessment.timeLimitSeconds)).toIso8601String(),
      answers: const <AssessmentAnswerModel>[],
      practicalScore: null,
      result: null,
      certificate: null,
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );
    return AssessmentStartResult(session: session, assessment: assessment);
  }

  Future<AssessmentAnswerModel> submitAnswer({
    required AssessmentSessionModel session,
    required AssessmentModel assessment,
    required String questionId,
    required int selectedIndex,
  }) async {
    if (ApiClient.instance.isEnabled && !session.id.startsWith('assessment_')) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/assessment-sessions/${Uri.encodeComponent(session.id)}/answer',
          <String, dynamic>{'questionId': questionId, 'selectedIndex': selectedIndex},
        );
        final answerJson = json['answer'];
        if (answerJson is Map<String, dynamic>) return AssessmentAnswerModel.fromJson(answerJson);
      } on Object {
        // Fallback to local scoring.
      }
    }
    final question = assessment.questions.firstWhere((item) => item.id == questionId);
    final isCorrect = selectedIndex == question.correctIndex;
    return AssessmentAnswerModel(
      questionId: question.id,
      selectedIndex: selectedIndex,
      isCorrect: isCorrect,
      earnedPoints: isCorrect ? question.points : 0,
      maxPoints: question.points,
      roundType: question.roundType,
      skillId: question.skillId,
      answeredAt: DateTime.now().toIso8601String(),
    );
  }

  Future<AssessmentCompleteResult> completeAssessment({
    required AssessmentSessionModel session,
    required AssessmentModel assessment,
    required Map<String, int> selectedAnswers,
    required int practicalScore,
  }) async {
    if (ApiClient.instance.isEnabled && !session.id.startsWith('assessment_')) {
      try {
        for (final entry in selectedAnswers.entries) {
          await submitAnswer(
            session: session,
            assessment: assessment,
            questionId: entry.key,
            selectedIndex: entry.value,
          );
        }
        final json = await ApiClient.instance.postMap(
          '/api/assessment-sessions/${Uri.encodeComponent(session.id)}/complete',
          <String, dynamic>{'practicalScore': practicalScore, 'displayName': session.displayName},
        );
        final sessionJson = json['session'];
        final assessmentJson = json['assessment'];
        final certificateJson = json['certificate'];
        if (sessionJson is Map<String, dynamic> && assessmentJson is Map<String, dynamic>) {
          return AssessmentCompleteResult(
            session: AssessmentSessionModel.fromJson(sessionJson),
            assessment: AssessmentModel.fromJson(assessmentJson),
            certificate: certificateJson is Map<String, dynamic> ? CertificateRecordModel.fromJson(certificateJson) : null,
          );
        }
      } on Object {
        // Fallback to local completion.
      }
    }

    final answers = <AssessmentAnswerModel>[];
    for (final question in assessment.questions) {
      final selected = selectedAnswers[question.id] ?? -1;
      final isCorrect = selected == question.correctIndex;
      answers.add(AssessmentAnswerModel(
        questionId: question.id,
        selectedIndex: selected,
        isCorrect: isCorrect,
        earnedPoints: isCorrect ? question.points : 0,
        maxPoints: question.points,
        roundType: question.roundType,
        skillId: question.skillId,
        answeredAt: DateTime.now().toIso8601String(),
      ));
    }
    final result = _calculateResult(assessment: assessment, session: session, answers: answers, practicalScore: practicalScore);
    CertificateRecordModel? certificate;
    if (result.passed) {
      certificate = _buildLocalCertificate(session: session, assessment: assessment, result: result);
      await _saveLocalCertificate(certificate);
    }
    final updated = AssessmentSessionModel(
      id: session.id,
      userId: session.userId,
      displayName: session.displayName,
      roleId: session.roleId,
      roleName: session.roleName,
      assessmentId: session.assessmentId,
      status: 'completed',
      timeLimitSeconds: session.timeLimitSeconds,
      startedAt: session.startedAt,
      expiresAt: session.expiresAt,
      answers: answers,
      practicalScore: practicalScore,
      result: result,
      certificate: certificate,
      createdAt: session.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
    return AssessmentCompleteResult(session: updated, assessment: assessment, certificate: certificate);
  }

  Future<List<CertificateRecordModel>> loadCertificates(String userId) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/users/${Uri.encodeComponent(userId)}/certificates');
        final items = json['certificates'];
        if (items is List) {
          return items.whereType<Map<String, dynamic>>().map(CertificateRecordModel.fromJson).toList(growable: false);
        }
      } on Object {
        // Fallback to local certificates.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localCertificatesKey);
    if (raw == null || raw.trim().isEmpty) return const <CertificateRecordModel>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <CertificateRecordModel>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CertificateRecordModel.fromJson)
        .where((certificate) => certificate.userId == userId)
        .toList(growable: false);
  }

  List<AssessmentModel> _assessmentsFromJson(Map<String, dynamic> json) {
    final items = json['assessments'];
    if (items is! List) return const <AssessmentModel>[];
    return items.whereType<Map<String, dynamic>>().map(AssessmentModel.fromJson).toList(growable: false);
  }

  AssessmentResultModel _calculateResult({
    required AssessmentModel assessment,
    required AssessmentSessionModel session,
    required List<AssessmentAnswerModel> answers,
    required int practicalScore,
  }) {
    final answerMap = <String, AssessmentAnswerModel>{for (final answer in answers) answer.questionId: answer};
    var earned = 0;
    var possible = 0;
    final buckets = <String, List<int>>{};
    for (final question in assessment.questions) {
      possible += question.points;
      buckets.putIfAbsent(question.roundType, () => <int>[0, 0]);
      buckets[question.roundType]![1] += question.points;
      if (answerMap[question.id]?.isCorrect == true) {
        earned += question.points;
        buckets[question.roundType]![0] += question.points;
      }
    }
    final questionScore = possible > 0 ? ((earned / possible) * 100).round() : 0;
    final clampedPractical = practicalScore.clamp(0, 100).toInt();
    final totalScore = ((questionScore * 0.8) + (clampedPractical * 0.2)).round().clamp(0, 100).toInt();
    final roundScores = <String, int>{};
    buckets.forEach((key, value) {
      roundScores[key] = value[1] > 0 ? ((value[0] / value[1]) * 100).round() : 0;
    });
    roundScores['practicalMiniGame'] = clampedPractical;
    final expiresAt = DateTime.tryParse(session.expiresAt);
    final timedOut = expiresAt != null && DateTime.now().isAfter(expiresAt);
    final answeredAll = assessment.questions.every((question) => answerMap.containsKey(question.id));
    final passed = answeredAll &&
        !timedOut &&
        totalScore >= assessment.minimumPassingScore &&
        clampedPractical >= assessment.minimumPracticalScore &&
        (roundScores['ethics'] ?? 0) >= assessment.minimumEthicsScore;
    final tips = <String>[];
    if (!answeredAll) tips.add('Answer every role-wise assessment question before retrying certification.');
    if (timedOut) tips.add('Complete the timed assessment before the countdown expires.');
    if (totalScore < assessment.minimumPassingScore) tips.add('Raise total score to at least ${assessment.minimumPassingScore}%.');
    if (clampedPractical < assessment.minimumPracticalScore) tips.add('Improve the practical mini-game score to at least ${assessment.minimumPracticalScore}%.');
    if ((roundScores['ethics'] ?? 0) < assessment.minimumEthicsScore) tips.add('Improve ethics and safety choices before certificate issue.');
    if (tips.isEmpty) tips.add('Passed. Save and share the certificate verification ID.');
    return AssessmentResultModel(
      totalScore: totalScore,
      questionScore: questionScore,
      practicalScore: clampedPractical,
      roundScores: roundScores,
      answeredQuestionCount: answers.length,
      totalQuestionCount: assessment.questions.length,
      minimumPassingScore: assessment.minimumPassingScore,
      minimumPracticalScore: assessment.minimumPracticalScore,
      minimumEthicsScore: assessment.minimumEthicsScore,
      timedOut: timedOut,
      passed: passed,
      resultLabel: passed ? 'Passed' : 'Failed',
      improvementTips: tips,
      completedAt: DateTime.now().toIso8601String(),
    );
  }

  CertificateRecordModel _buildLocalCertificate({
    required AssessmentSessionModel session,
    required AssessmentModel assessment,
    required AssessmentResultModel result,
  }) {
    final now = DateTime.now();
    final token = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    final prefix = assessment.roleId.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toUpperCase().padRight(4, 'X').substring(0, 4);
    final verificationId = 'CCA-$prefix-${now.year}-$token';
    return CertificateRecordModel(
      id: 'cert_${now.microsecondsSinceEpoch}',
      verificationId: verificationId,
      userId: session.userId,
      recipientName: session.displayName,
      roleId: assessment.roleId,
      roleName: assessment.roleName,
      assessmentId: assessment.id,
      assessmentTitle: assessment.title,
      assessmentSessionId: session.id,
      totalScore: result.totalScore,
      skillIds: assessment.skillIds,
      templateId: assessment.certificateTemplateId,
      issuer: 'Career Chaos Academy',
      status: 'valid',
      issuedAt: now.toIso8601String(),
      pdfPath: '/api/certificates/$verificationId/pdf',
      verificationPath: '/api/certificates/$verificationId',
    );
  }

  Future<void> _saveLocalCertificate(CertificateRecordModel certificate) async {
    final existing = await loadCertificates(certificate.userId);
    final updated = <CertificateRecordModel>[certificate, ...existing]
        .where((item) => item.verificationId == certificate.verificationId || item.roleId != certificate.roleId)
        .take(30)
        .toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localCertificatesKey,
      jsonEncode(updated.map((item) => item.toJson()).toList(growable: false)),
    );
  }
}

class CertificationServiceException implements Exception {
  final String message;
  const CertificationServiceException(this.message);

  @override
  String toString() => message;
}
