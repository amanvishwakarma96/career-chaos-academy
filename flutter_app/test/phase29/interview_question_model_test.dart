import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/interview_question_model.dart';

void main() {
  test('interview question model parses role-wise round and rubric', () {
    final question = InterviewQuestionModel.fromJson(jsonDecode('''
    {
      "id":"developer_technical_round_1",
      "roleId":"developer",
      "roleName":"Developer",
      "roundType":"technical",
      "difficulty":"intermediate",
      "prompt":"How do you debug a production issue?",
      "skillTags":["debugging","testing"],
      "expectedKeywords":["logs","test","rollback"],
      "rubric":{"clarity":20,"roleKnowledge":25,"ethics":20},
      "sampleStrongAnswer":"Use logs, tests, review, and rollback."
    }
    ''') as Map<String, dynamic>);

    expect(question.roleId, 'developer');
    expect(question.roundLabel, 'Technical Round');
    expect(question.expectedKeywords, contains('rollback'));
    expect(question.rubric['roleKnowledge'], 25);
  });

  test('feedback and readiness report keep score, tips, and saved report data', () {
    final feedback = InterviewAnswerFeedbackModel.fromJson({
      'questionId': 'q1',
      'answer': 'I would test and communicate the risk.',
      'score': 74,
      'rubricScores': {'clarity': 16, 'roleKnowledge': 18, 'ethics': 18},
      'strengths': ['Clear answer structure'],
      'improvementTips': ['Add more metrics.'],
      'matchedKeywords': ['test'],
      'missingKeywords': ['rollback'],
      'aiSummary': 'Good base answer.',
      'retryPrompt': 'Retry with STAR format.',
      'createdAt': '2026-06-17T00:00:00.000Z',
    });

    final report = InterviewReadinessReportModel.fromJson({
      'id': 'r1',
      'userId': 'u1',
      'roleId': 'developer',
      'roleName': 'Developer',
      'totalScore': 74,
      'readinessLevel': 'Almost Ready',
      'feedbackItems': [feedback.toJson()],
      'strengths': feedback.strengths,
      'improvementAreas': feedback.improvementTips,
      'nextSteps': ['Retry weakest round.'],
      'savedAt': '2026-06-17T00:00:00.000Z',
    });

    expect(feedback.score, 74);
    expect(feedback.improvementTips.single, 'Add more metrics.');
    expect(report.readinessLevel, 'Almost Ready');
    expect(report.feedbackItems.single.questionId, 'q1');
  });
}
