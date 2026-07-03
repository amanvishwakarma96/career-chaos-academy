class ProfessionalSkillModel {
  final String id;
  final String name;
  final String level;
  final String description;

  const ProfessionalSkillModel({
    required this.id,
    required this.name,
    required this.level,
    required this.description,
  });

  factory ProfessionalSkillModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalSkillModel(
      id: _readString(json['id']),
      name: _readString(json['name']),
      level: _readString(json['level'], fallback: 'beginner'),
      description: _readString(json['description']),
    );
  }
}

class ProfessionalWorkflowModel {
  final String id;
  final String title;
  final String level;
  final List<String> steps;
  final List<String> constraints;

  const ProfessionalWorkflowModel({
    required this.id,
    required this.title,
    required this.level,
    this.steps = const <String>[],
    this.constraints = const <String>[],
  });

  factory ProfessionalWorkflowModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalWorkflowModel(
      id: _readString(json['id']),
      title: _readString(json['title']),
      level: _readString(json['level'], fallback: 'beginner'),
      steps: _readStringList(json['steps']),
      constraints: _readStringList(json['constraints']),
    );
  }
}

class ProfessionalGlossaryTermModel {
  final String term;
  final String definition;

  const ProfessionalGlossaryTermModel({
    required this.term,
    required this.definition,
  });

  factory ProfessionalGlossaryTermModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalGlossaryTermModel(
      term: _readString(json['term']),
      definition: _readString(json['definition']),
    );
  }
}

class RoleSkillMapModel {
  final String roleId;
  final String roleName;
  final String mentorName;
  final List<ProfessionalSkillModel> skills;
  final List<ProfessionalWorkflowModel> workflows;
  final List<ProfessionalGlossaryTermModel> glossary;
  final List<String> safetyGuardrails;

  const RoleSkillMapModel({
    required this.roleId,
    required this.roleName,
    required this.mentorName,
    this.skills = const <ProfessionalSkillModel>[],
    this.workflows = const <ProfessionalWorkflowModel>[],
    this.glossary = const <ProfessionalGlossaryTermModel>[],
    this.safetyGuardrails = const <String>[],
  });

  factory RoleSkillMapModel.fromJson(Map<String, dynamic> json) {
    return RoleSkillMapModel(
      roleId: _readString(json['roleId']),
      roleName: _readString(json['roleName']),
      mentorName: _readString(json['mentorName'], fallback: 'Mentor'),
      skills: _readObjectList(json['skills'])
          .map(ProfessionalSkillModel.fromJson)
          .where((skill) => skill.id.isNotEmpty)
          .toList(growable: false),
      workflows: _readObjectList(json['workflows'])
          .map(ProfessionalWorkflowModel.fromJson)
          .where((workflow) => workflow.id.isNotEmpty)
          .toList(growable: false),
      glossary: _readObjectList(json['glossary'])
          .map(ProfessionalGlossaryTermModel.fromJson)
          .where((term) => term.term.isNotEmpty)
          .toList(growable: false),
      safetyGuardrails: _readStringList(json['safetyGuardrails']),
    );
  }

  bool get hasAdvancedSkill => skills.any((skill) => skill.level == 'advanced');
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  return fallback;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _readObjectList(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value.whereType<Map<String, dynamic>>().toList(growable: false);
}
