class AssessmentAnswerModel {
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;
  final int earnedPoints;
  final int maxPoints;
  final String roundType;
  final String skillId;
  final String answeredAt;

  const AssessmentAnswerModel({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.earnedPoints,
    required this.maxPoints,
    required this.roundType,
    required this.skillId,
    required this.answeredAt,
  });

  factory AssessmentAnswerModel.fromJson(Map<String, dynamic> json) {
    return AssessmentAnswerModel(
      questionId: _string(json['questionId']),
      selectedIndex: _int(json['selectedIndex'], fallback: -1),
      isCorrect: json['isCorrect'] == true,
      earnedPoints: _int(json['earnedPoints']),
      maxPoints: _int(json['maxPoints']),
      roundType: _string(json['roundType'], fallback: 'technical'),
      skillId: _string(json['skillId']),
      answeredAt: _string(json['answeredAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'isCorrect': isCorrect,
        'earnedPoints': earnedPoints,
        'maxPoints': maxPoints,
        'roundType': roundType,
        'skillId': skillId,
        'answeredAt': answeredAt,
      };
}

class AssessmentResultModel {
  final int totalScore;
  final int questionScore;
  final int practicalScore;
  final Map<String, int> roundScores;
  final int answeredQuestionCount;
  final int totalQuestionCount;
  final int minimumPassingScore;
  final int minimumPracticalScore;
  final int minimumEthicsScore;
  final bool timedOut;
  final bool passed;
  final String resultLabel;
  final List<String> improvementTips;
  final String completedAt;

  const AssessmentResultModel({
    required this.totalScore,
    required this.questionScore,
    required this.practicalScore,
    required this.roundScores,
    required this.answeredQuestionCount,
    required this.totalQuestionCount,
    required this.minimumPassingScore,
    required this.minimumPracticalScore,
    required this.minimumEthicsScore,
    required this.timedOut,
    required this.passed,
    required this.resultLabel,
    required this.improvementTips,
    required this.completedAt,
  });

  factory AssessmentResultModel.fromJson(Map<String, dynamic> json) {
    return AssessmentResultModel(
      totalScore: _int(json['totalScore']),
      questionScore: _int(json['questionScore']),
      practicalScore: _int(json['practicalScore']),
      roundScores: _intMap(json['roundScores']),
      answeredQuestionCount: _int(json['answeredQuestionCount']),
      totalQuestionCount: _int(json['totalQuestionCount']),
      minimumPassingScore: _int(json['minimumPassingScore'], fallback: 70),
      minimumPracticalScore: _int(json['minimumPracticalScore'], fallback: 60),
      minimumEthicsScore: _int(json['minimumEthicsScore'], fallback: 60),
      timedOut: json['timedOut'] == true,
      passed: json['passed'] == true,
      resultLabel: _string(json['resultLabel'], fallback: 'Failed'),
      improvementTips: _stringList(json['improvementTips']),
      completedAt: _string(json['completedAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'totalScore': totalScore,
        'questionScore': questionScore,
        'practicalScore': practicalScore,
        'roundScores': roundScores,
        'answeredQuestionCount': answeredQuestionCount,
        'totalQuestionCount': totalQuestionCount,
        'minimumPassingScore': minimumPassingScore,
        'minimumPracticalScore': minimumPracticalScore,
        'minimumEthicsScore': minimumEthicsScore,
        'timedOut': timedOut,
        'passed': passed,
        'resultLabel': resultLabel,
        'improvementTips': improvementTips,
        'completedAt': completedAt,
      };
}

class CertificateRecordModel {
  final String id;
  final String verificationId;
  final String userId;
  final String recipientName;
  final String roleId;
  final String roleName;
  final String assessmentId;
  final String assessmentTitle;
  final String assessmentSessionId;
  final int totalScore;
  final List<String> skillIds;
  final String templateId;
  final String issuer;
  final String status;
  final String issuedAt;
  final String pdfPath;
  final String verificationPath;

  const CertificateRecordModel({
    required this.id,
    required this.verificationId,
    required this.userId,
    required this.recipientName,
    required this.roleId,
    required this.roleName,
    required this.assessmentId,
    required this.assessmentTitle,
    required this.assessmentSessionId,
    required this.totalScore,
    this.skillIds = const <String>[],
    required this.templateId,
    required this.issuer,
    required this.status,
    required this.issuedAt,
    required this.pdfPath,
    required this.verificationPath,
  });

  factory CertificateRecordModel.fromJson(Map<String, dynamic> json) {
    return CertificateRecordModel(
      id: _string(json['id']),
      verificationId: _string(json['verificationId']),
      userId: _string(json['userId']),
      recipientName: _string(json['recipientName'], fallback: 'Career Chaos Learner'),
      roleId: _string(json['roleId']),
      roleName: _string(json['roleName'], fallback: 'Career Role'),
      assessmentId: _string(json['assessmentId']),
      assessmentTitle: _string(json['assessmentTitle'], fallback: 'Final Assessment'),
      assessmentSessionId: _string(json['assessmentSessionId']),
      totalScore: _int(json['totalScore']),
      skillIds: _stringList(json['skillIds']),
      templateId: _string(json['templateId'], fallback: 'career_chaos_certificate_v1'),
      issuer: _string(json['issuer'], fallback: 'Career Chaos Academy'),
      status: _string(json['status'], fallback: 'valid'),
      issuedAt: _string(json['issuedAt'], fallback: DateTime.now().toIso8601String()),
      pdfPath: _string(json['pdfPath']),
      verificationPath: _string(json['verificationPath']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'verificationId': verificationId,
        'userId': userId,
        'recipientName': recipientName,
        'roleId': roleId,
        'roleName': roleName,
        'assessmentId': assessmentId,
        'assessmentTitle': assessmentTitle,
        'assessmentSessionId': assessmentSessionId,
        'totalScore': totalScore,
        'skillIds': skillIds,
        'templateId': templateId,
        'issuer': issuer,
        'status': status,
        'issuedAt': issuedAt,
        'pdfPath': pdfPath,
        'verificationPath': verificationPath,
      };
}

class AssessmentSessionModel {
  final String id;
  final String userId;
  final String displayName;
  final String roleId;
  final String roleName;
  final String assessmentId;
  final String status;
  final int timeLimitSeconds;
  final String startedAt;
  final String expiresAt;
  final List<AssessmentAnswerModel> answers;
  final int? practicalScore;
  final AssessmentResultModel? result;
  final CertificateRecordModel? certificate;
  final String createdAt;
  final String updatedAt;

  const AssessmentSessionModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.roleId,
    required this.roleName,
    required this.assessmentId,
    required this.status,
    required this.timeLimitSeconds,
    required this.startedAt,
    required this.expiresAt,
    required this.answers,
    required this.practicalScore,
    required this.result,
    required this.certificate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssessmentSessionModel.fromJson(Map<String, dynamic> json) {
    return AssessmentSessionModel(
      id: _string(json['id']),
      userId: _string(json['userId']),
      displayName: _string(json['displayName'], fallback: 'Career Chaos Learner'),
      roleId: _string(json['roleId']),
      roleName: _string(json['roleName'], fallback: 'Career Role'),
      assessmentId: _string(json['assessmentId']),
      status: _string(json['status'], fallback: 'in_progress'),
      timeLimitSeconds: _int(json['timeLimitSeconds'], fallback: 900),
      startedAt: _string(json['startedAt'], fallback: DateTime.now().toIso8601String()),
      expiresAt: _string(json['expiresAt'], fallback: DateTime.now().add(const Duration(minutes: 15)).toIso8601String()),
      answers: _mapList(json['answers']).map(AssessmentAnswerModel.fromJson).toList(growable: false),
      practicalScore: json['practicalScore'] == null ? null : _int(json['practicalScore']),
      result: json['result'] is Map<String, dynamic> ? AssessmentResultModel.fromJson(json['result'] as Map<String, dynamic>) : null,
      certificate: json['certificate'] is Map<String, dynamic> ? CertificateRecordModel.fromJson(json['certificate'] as Map<String, dynamic>) : null,
      createdAt: _string(json['createdAt'], fallback: DateTime.now().toIso8601String()),
      updatedAt: _string(json['updatedAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'displayName': displayName,
        'roleId': roleId,
        'roleName': roleName,
        'assessmentId': assessmentId,
        'status': status,
        'timeLimitSeconds': timeLimitSeconds,
        'startedAt': startedAt,
        'expiresAt': expiresAt,
        'answers': answers.map((item) => item.toJson()).toList(growable: false),
        'practicalScore': practicalScore,
        'result': result?.toJson(),
        'certificate': certificate?.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
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

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) return const <String, int>{};
  final result = <String, int>{};
  value.forEach((key, item) {
    if (key is String && key.trim().isNotEmpty) result[key] = _int(item);
  });
  return Map<String, int>.unmodifiable(result);
}
