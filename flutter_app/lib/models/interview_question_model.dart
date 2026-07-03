class InterviewQuestionModel {
  final String id;
  final String roleId;
  final String roleName;
  final String roundType;
  final String difficulty;
  final String prompt;
  final List<String> skillTags;
  final List<String> expectedKeywords;
  final Map<String, int> rubric;
  final String sampleStrongAnswer;

  const InterviewQuestionModel({
    required this.id,
    required this.roleId,
    required this.roleName,
    required this.roundType,
    required this.difficulty,
    required this.prompt,
    this.skillTags = const <String>[],
    this.expectedKeywords = const <String>[],
    this.rubric = const <String, int>{},
    this.sampleStrongAnswer = '',
  });

  factory InterviewQuestionModel.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionModel(
      id: _string(json['id']),
      roleId: _string(json['roleId']),
      roleName: _string(json['roleName']),
      roundType: _string(json['roundType'], fallback: 'technical'),
      difficulty: _string(json['difficulty'], fallback: 'beginner'),
      prompt: _string(json['prompt']),
      skillTags: _stringList(json['skillTags']),
      expectedKeywords: _stringList(json['expectedKeywords']),
      rubric: _intMap(json['rubric']),
      sampleStrongAnswer: _string(json['sampleStrongAnswer']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'roleId': roleId,
        'roleName': roleName,
        'roundType': roundType,
        'difficulty': difficulty,
        'prompt': prompt,
        'skillTags': skillTags,
        'expectedKeywords': expectedKeywords,
        'rubric': rubric,
        'sampleStrongAnswer': sampleStrongAnswer,
      };

  String get roundLabel {
    switch (roundType) {
      case 'technical':
        return 'Technical Round';
      case 'behavioral':
        return 'Behavioral Round';
      case 'situation':
        return 'Situation Round';
      default:
        return '${roundType[0].toUpperCase()}${roundType.substring(1)} Round';
    }
  }
}

class InterviewAnswerFeedbackModel {
  final String questionId;
  final String answer;
  final int score;
  final Map<String, int> rubricScores;
  final List<String> strengths;
  final List<String> improvementTips;
  final List<String> matchedKeywords;
  final List<String> missingKeywords;
  final String aiSummary;
  final String retryPrompt;
  final String createdAt;

  const InterviewAnswerFeedbackModel({
    required this.questionId,
    required this.answer,
    required this.score,
    required this.rubricScores,
    required this.strengths,
    required this.improvementTips,
    this.matchedKeywords = const <String>[],
    this.missingKeywords = const <String>[],
    this.aiSummary = '',
    this.retryPrompt = '',
    required this.createdAt,
  });

  factory InterviewAnswerFeedbackModel.fromJson(Map<String, dynamic> json) {
    return InterviewAnswerFeedbackModel(
      questionId: _string(json['questionId']),
      answer: _string(json['answer']),
      score: _int(json['score']),
      rubricScores: _intMap(json['rubricScores']),
      strengths: _stringList(json['strengths']),
      improvementTips: _stringList(json['improvementTips']),
      matchedKeywords: _stringList(json['matchedKeywords']),
      missingKeywords: _stringList(json['missingKeywords']),
      aiSummary: _string(json['aiSummary']),
      retryPrompt: _string(json['retryPrompt']),
      createdAt: _string(json['createdAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'questionId': questionId,
        'answer': answer,
        'score': score,
        'rubricScores': rubricScores,
        'strengths': strengths,
        'improvementTips': improvementTips,
        'matchedKeywords': matchedKeywords,
        'missingKeywords': missingKeywords,
        'aiSummary': aiSummary,
        'retryPrompt': retryPrompt,
        'createdAt': createdAt,
      };
}

class InterviewReadinessReportModel {
  final String id;
  final String userId;
  final String roleId;
  final String roleName;
  final int totalScore;
  final String readinessLevel;
  final List<InterviewAnswerFeedbackModel> feedbackItems;
  final List<String> strengths;
  final List<String> improvementAreas;
  final List<String> nextSteps;
  final String savedAt;

  const InterviewReadinessReportModel({
    required this.id,
    required this.userId,
    required this.roleId,
    required this.roleName,
    required this.totalScore,
    required this.readinessLevel,
    required this.feedbackItems,
    this.strengths = const <String>[],
    this.improvementAreas = const <String>[],
    this.nextSteps = const <String>[],
    required this.savedAt,
  });

  factory InterviewReadinessReportModel.fromJson(Map<String, dynamic> json) {
    return InterviewReadinessReportModel(
      id: _string(json['id']),
      userId: _string(json['userId']),
      roleId: _string(json['roleId']),
      roleName: _string(json['roleName']),
      totalScore: _int(json['totalScore']),
      readinessLevel: _string(json['readinessLevel'], fallback: 'Needs practice'),
      feedbackItems: _mapList(json['feedbackItems'])
          .map(InterviewAnswerFeedbackModel.fromJson)
          .toList(growable: false),
      strengths: _stringList(json['strengths']),
      improvementAreas: _stringList(json['improvementAreas']),
      nextSteps: _stringList(json['nextSteps']),
      savedAt: _string(json['savedAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'roleId': roleId,
        'roleName': roleName,
        'totalScore': totalScore,
        'readinessLevel': readinessLevel,
        'feedbackItems': feedbackItems.map((item) => item.toJson()).toList(growable: false),
        'strengths': strengths,
        'improvementAreas': improvementAreas,
        'nextSteps': nextSteps,
        'savedAt': savedAt,
      };
}

String _string(Object? value, {String fallback = ''}) {
  return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return fallback;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().where((item) => item.trim().isNotEmpty).map((item) => item.trim()).toList(growable: false);
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) return const <String, int>{};
  final result = <String, int>{};
  value.forEach((key, item) {
    if (key is String && key.trim().isNotEmpty) result[key] = _int(item);
  });
  return Map<String, int>.unmodifiable(result);
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}
