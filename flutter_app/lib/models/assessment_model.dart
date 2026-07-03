class AssessmentModel {
  final String id;
  final String roleId;
  final String roleName;
  final String title;
  final String description;
  final String version;
  final int timeLimitSeconds;
  final int minimumPassingScore;
  final int minimumPracticalScore;
  final int minimumEthicsScore;
  final String certificateTemplateId;
  final List<String> skillIds;
  final List<AssessmentQuestionModel> questions;
  final PracticalMiniGameAssessmentModel practicalMiniGame;
  final Map<String, int> rubric;

  const AssessmentModel({
    required this.id,
    required this.roleId,
    required this.roleName,
    required this.title,
    required this.description,
    required this.version,
    required this.timeLimitSeconds,
    required this.minimumPassingScore,
    required this.minimumPracticalScore,
    required this.minimumEthicsScore,
    required this.certificateTemplateId,
    required this.skillIds,
    required this.questions,
    required this.practicalMiniGame,
    required this.rubric,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      id: _string(json['id']),
      roleId: _string(json['roleId']),
      roleName: _string(json['roleName'], fallback: 'Career Role'),
      title: _string(json['title'], fallback: 'Final Assessment'),
      description: _string(json['description']),
      version: _string(json['version'], fallback: '30.0.0'),
      timeLimitSeconds: _int(json['timeLimitSeconds'], fallback: 900),
      minimumPassingScore: _int(json['minimumPassingScore'], fallback: 70),
      minimumPracticalScore: _int(json['minimumPracticalScore'], fallback: 60),
      minimumEthicsScore: _int(json['minimumEthicsScore'], fallback: 60),
      certificateTemplateId: _string(json['certificateTemplateId'], fallback: 'career_chaos_certificate_v1'),
      skillIds: _stringList(json['skillIds']),
      questions: _mapList(json['questions']).map(AssessmentQuestionModel.fromJson).toList(growable: false),
      practicalMiniGame: PracticalMiniGameAssessmentModel.fromJson(_map(json['practicalMiniGame'])),
      rubric: _intMap(json['rubric']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'roleId': roleId,
        'roleName': roleName,
        'title': title,
        'description': description,
        'version': version,
        'timeLimitSeconds': timeLimitSeconds,
        'minimumPassingScore': minimumPassingScore,
        'minimumPracticalScore': minimumPracticalScore,
        'minimumEthicsScore': minimumEthicsScore,
        'certificateTemplateId': certificateTemplateId,
        'skillIds': skillIds,
        'questions': questions.map((item) => item.toJson()).toList(growable: false),
        'practicalMiniGame': practicalMiniGame.toJson(),
        'rubric': rubric,
      };
}

class AssessmentQuestionModel {
  final String id;
  final String roleId;
  final String roundType;
  final String skillId;
  final String skillName;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int points;
  final List<String> tags;

  const AssessmentQuestionModel({
    required this.id,
    required this.roleId,
    required this.roundType,
    required this.skillId,
    required this.skillName,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.points,
    required this.tags,
  });

  factory AssessmentQuestionModel.fromJson(Map<String, dynamic> json) {
    return AssessmentQuestionModel(
      id: _string(json['id']),
      roleId: _string(json['roleId']),
      roundType: _string(json['roundType'], fallback: 'technical'),
      skillId: _string(json['skillId']),
      skillName: _string(json['skillName'], fallback: 'Role Skill'),
      prompt: _string(json['prompt']),
      options: _stringList(json['options']),
      correctIndex: _int(json['correctIndex'], fallback: -1),
      explanation: _string(json['explanation']),
      points: _int(json['points'], fallback: 20),
      tags: _stringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'roleId': roleId,
        'roundType': roundType,
        'skillId': skillId,
        'skillName': skillName,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'points': points,
        'tags': tags,
      };

  String get roundLabel {
    switch (roundType) {
      case 'technical':
        return 'Technical Test';
      case 'practical_judgement':
        return 'Practical Judgement';
      case 'ethics':
        return 'Ethics Gate';
      default:
        return roundType.replaceAll('_', ' ');
    }
  }
}

class PracticalMiniGameAssessmentModel {
  final String id;
  final String title;
  final String miniGameType;
  final String skillId;
  final String skillName;
  final String instructions;
  final int maxScore;
  final int minimumScore;
  final int durationSeconds;

  const PracticalMiniGameAssessmentModel({
    required this.id,
    required this.title,
    required this.miniGameType,
    required this.skillId,
    required this.skillName,
    required this.instructions,
    required this.maxScore,
    required this.minimumScore,
    required this.durationSeconds,
  });

  factory PracticalMiniGameAssessmentModel.fromJson(Map<String, dynamic> json) {
    return PracticalMiniGameAssessmentModel(
      id: _string(json['id']),
      title: _string(json['title'], fallback: 'Practical Mini-Game Assessment'),
      miniGameType: _string(json['miniGameType'], fallback: 'scenario_skill_check'),
      skillId: _string(json['skillId']),
      skillName: _string(json['skillName'], fallback: 'Role Skill'),
      instructions: _string(json['instructions']),
      maxScore: _int(json['maxScore'], fallback: 100),
      minimumScore: _int(json['minimumScore'], fallback: 60),
      durationSeconds: _int(json['durationSeconds'], fallback: 180),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'miniGameType': miniGameType,
        'skillId': skillId,
        'skillName': skillName,
        'instructions': instructions,
        'maxScore': maxScore,
        'minimumScore': minimumScore,
        'durationSeconds': durationSeconds,
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

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : const <String, dynamic>{};
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
