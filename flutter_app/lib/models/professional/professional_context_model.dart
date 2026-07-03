class ProfessionalContextModel {
  final String learningObjective;
  final String skillLevel;
  final String workflowId;
  final List<String> skillTags;
  final List<String> realWorldConstraints;
  final List<String> safetyGuardrails;
  final String practicalTakeaway;
  final String safeExplanation;
  final String mentorFeedback;

  const ProfessionalContextModel({
    this.learningObjective = '',
    this.skillLevel = 'beginner',
    this.workflowId = '',
    this.skillTags = const <String>[],
    this.realWorldConstraints = const <String>[],
    this.safetyGuardrails = const <String>[],
    this.practicalTakeaway = '',
    this.safeExplanation = '',
    this.mentorFeedback = '',
  });

  static const empty = ProfessionalContextModel();

  factory ProfessionalContextModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalContextModel(
      learningObjective: _readString(json['learningObjective']),
      skillLevel: _readString(json['skillLevel'], fallback: 'beginner'),
      workflowId: _readString(json['workflowId']),
      skillTags: _readStringList(json['skillTags']),
      realWorldConstraints: _readStringList(json['realWorldConstraints']),
      safetyGuardrails: _readStringList(json['safetyGuardrails']),
      practicalTakeaway: _readString(json['practicalTakeaway']),
      safeExplanation: _readString(json['safeExplanation']),
      mentorFeedback: _readString(json['mentorFeedback']),
    );
  }

  bool get hasContent {
    return learningObjective.isNotEmpty ||
        practicalTakeaway.isNotEmpty ||
        safeExplanation.isNotEmpty ||
        mentorFeedback.isNotEmpty ||
        realWorldConstraints.isNotEmpty ||
        safetyGuardrails.isNotEmpty ||
        skillTags.isNotEmpty;
  }
}

class OutcomeProfessionalFeedbackModel {
  final String mentorFeedback;
  final String safeExplanation;
  final String practicalTakeaway;

  const OutcomeProfessionalFeedbackModel({
    this.mentorFeedback = '',
    this.safeExplanation = '',
    this.practicalTakeaway = '',
  });

  static const empty = OutcomeProfessionalFeedbackModel();

  factory OutcomeProfessionalFeedbackModel.fromJson(Map<String, dynamic> json) {
    return OutcomeProfessionalFeedbackModel(
      mentorFeedback: _readString(json['mentorFeedback']),
      safeExplanation: _readString(json['safeExplanation']),
      practicalTakeaway: _readString(json['practicalTakeaway']),
    );
  }

  bool get hasContent =>
      mentorFeedback.isNotEmpty || safeExplanation.isNotEmpty || practicalTakeaway.isNotEmpty;
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
