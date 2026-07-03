import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/assessment_model.dart';
import 'package:career_chaos_academy/models/assessment_session_model.dart';

void main() {
  test('assessment model parses timed role-wise certification content', () {
    final assessment = AssessmentModel.fromJson(jsonDecode('''
    {
      "id":"developer_final_assessment_v1",
      "roleId":"developer",
      "roleName":"Developer",
      "title":"Developer Final Certification Assessment",
      "description":"Timed role-wise assessment",
      "version":"30.0.0",
      "timeLimitSeconds":900,
      "minimumPassingScore":70,
      "minimumPracticalScore":60,
      "minimumEthicsScore":60,
      "certificateTemplateId":"career_chaos_certificate_v1",
      "skillIds":["debugging","release_safety"],
      "questions":[{
        "id":"q1",
        "roleId":"developer",
        "roundType":"technical",
        "skillId":"debugging",
        "skillName":"Debugging",
        "prompt":"What should you do first?",
        "options":["Reproduce and document","Skip testing"],
        "correctIndex":0,
        "explanation":"Evidence first.",
        "points":20,
        "tags":["debugging"]
      }],
      "practicalMiniGame":{
        "id":"dev_practical",
        "title":"Debugging Practical Challenge",
        "miniGameType":"scenario_skill_check",
        "skillId":"debugging",
        "skillName":"Debugging",
        "instructions":"Inspect, choose, explain.",
        "maxScore":100,
        "minimumScore":60,
        "durationSeconds":180
      },
      "rubric":{"technical":40,"practicalMiniGame":20}
    }
    ''') as Map<String, dynamic>);

    expect(assessment.roleId, 'developer');
    expect(assessment.timeLimitSeconds, 900);
    expect(assessment.questions.single.roundLabel, 'Technical Test');
    expect(assessment.practicalMiniGame.minimumScore, 60);
    expect(assessment.certificateTemplateId, 'career_chaos_certificate_v1');
  });

  test('assessment session stores pass result and certificate verification id', () {
    final result = AssessmentResultModel.fromJson({
      'totalScore': 88,
      'questionScore': 90,
      'practicalScore': 80,
      'roundScores': {'technical': 100, 'ethics': 100, 'practicalMiniGame': 80},
      'answeredQuestionCount': 4,
      'totalQuestionCount': 4,
      'minimumPassingScore': 70,
      'minimumPracticalScore': 60,
      'minimumEthicsScore': 60,
      'timedOut': false,
      'passed': true,
      'resultLabel': 'Passed',
      'improvementTips': ['Passed. Save and share the certificate verification ID.'],
      'completedAt': '2026-06-17T00:00:00.000Z'
    });

    final certificate = CertificateRecordModel.fromJson({
      'id': 'cert-1',
      'verificationId': 'CCA-DEVE-2026-ABC123',
      'userId': 'u1',
      'recipientName': 'Learner',
      'roleId': 'developer',
      'roleName': 'Developer',
      'assessmentId': 'developer_final_assessment_v1',
      'assessmentTitle': 'Developer Final Certification Assessment',
      'assessmentSessionId': 's1',
      'totalScore': 88,
      'skillIds': ['debugging'],
      'templateId': 'career_chaos_certificate_v1',
      'issuer': 'Career Chaos Academy',
      'status': 'valid',
      'issuedAt': '2026-06-17T00:00:00.000Z',
      'pdfPath': '/api/certificates/CCA-DEVE-2026-ABC123/pdf',
      'verificationPath': '/api/certificates/CCA-DEVE-2026-ABC123'
    });

    final session = AssessmentSessionModel.fromJson({
      'id': 's1',
      'userId': 'u1',
      'displayName': 'Learner',
      'roleId': 'developer',
      'roleName': 'Developer',
      'assessmentId': 'developer_final_assessment_v1',
      'status': 'completed',
      'timeLimitSeconds': 900,
      'startedAt': '2026-06-17T00:00:00.000Z',
      'expiresAt': '2026-06-17T00:15:00.000Z',
      'answers': [{'questionId': 'q1', 'selectedIndex': 0, 'isCorrect': true, 'earnedPoints': 20, 'maxPoints': 20}],
      'practicalScore': 80,
      'result': result.toJson(),
      'certificate': certificate.toJson(),
      'createdAt': '2026-06-17T00:00:00.000Z',
      'updatedAt': '2026-06-17T00:05:00.000Z'
    });

    expect(session.result?.passed, isTrue);
    expect(session.certificate?.verificationId, startsWith('CCA-'));
    expect(session.certificate?.pdfPath, contains('/pdf'));
  });
}
