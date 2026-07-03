import '../core/json_reader.dart';
import 'debrief_model.dart';
import 'relationship_score_model.dart';
import 'reputation_model.dart';
import 'professional/professional_context_model.dart';

class OutcomeModel {
  final String title;
  final String description;
  final String moralLesson;
  final List<String> setFlags;
  final List<String> clearFlags;
  final List<String> unlockCleanupMissionIds;
  final ReputationModel reputationImpact;
  final List<String> setStoryFlags;
  final List<String> clearStoryFlags;
  final RelationshipScoreModel relationshipImpact;
  final List<String> delayedConsequenceMessages;
  final String? nextChapterOverrideId;
  final String consequenceSummary;
  final DebriefModel debrief;
  final OutcomeProfessionalFeedbackModel professionalFeedback;

  const OutcomeModel({
    required this.title,
    required this.description,
    required this.moralLesson,
    this.setFlags = const <String>[],
    this.clearFlags = const <String>[],
    this.unlockCleanupMissionIds = const <String>[],
    this.reputationImpact = ReputationModel.zero,
    this.setStoryFlags = const <String>[],
    this.clearStoryFlags = const <String>[],
    this.relationshipImpact = RelationshipScoreModel.zero,
    this.delayedConsequenceMessages = const <String>[],
    this.nextChapterOverrideId,
    this.consequenceSummary = '',
    this.debrief = DebriefModel.empty,
    this.professionalFeedback = OutcomeProfessionalFeedbackModel.empty,
  });

  factory OutcomeModel.fromJson(Map<String, dynamic> json) {
    return OutcomeModel(
      title: JsonReader.readString(json, 'title', parent: 'outcome'),
      description: JsonReader.readString(
        json,
        'description',
        parent: 'outcome',
      ),
      moralLesson: JsonReader.readString(
        json,
        'moralLesson',
        parent: 'outcome',
      ),
      setFlags: _readStringList(json['setFlags']),
      clearFlags: _readStringList(json['clearFlags']),
      unlockCleanupMissionIds: _readStringList(json['unlockCleanupMissionIds']),
      reputationImpact: _readReputation(json['reputationImpact']),
      setStoryFlags: _readStringList(json['setStoryFlags'] ?? json['storyFlagsSet']),
      clearStoryFlags: _readStringList(json['clearStoryFlags'] ?? json['storyFlagsCleared']),
      relationshipImpact: _readRelationship(json['relationshipImpact']),
      delayedConsequenceMessages: _readStringList(json['delayedConsequenceMessages']),
      nextChapterOverrideId: _readNullableString(json['nextChapterOverrideId']),
      consequenceSummary: _readOptionalString(json['consequenceSummary']),
      debrief: _readDebrief(json['debrief']),
      professionalFeedback: _readProfessionalFeedback(json),
    );
  }


  String get mentorFeedback => professionalFeedback.mentorFeedback;
  String get safeExplanation => professionalFeedback.safeExplanation;
  String get practicalTakeaway => professionalFeedback.practicalTakeaway;

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static ReputationModel _readReputation(Object? value) {
    if (value is Map<String, dynamic>) {
      return ReputationModel.fromJson(value);
    }
    return ReputationModel.zero;
  }

  static RelationshipScoreModel _readRelationship(Object? value) {
    if (value is Map<String, dynamic>) {
      return RelationshipScoreModel.fromJson(value);
    }
    return RelationshipScoreModel.zero;
  }


  static OutcomeProfessionalFeedbackModel _readProfessionalFeedback(
    Map<String, dynamic> json,
  ) {
    final professional = json['professionalFeedback'];
    final source = <String, dynamic>{};
    if (professional is Map<String, dynamic>) {
      source.addAll(professional);
    }
    for (final key in <String>[
      'mentorFeedback',
      'safeExplanation',
      'practicalTakeaway',
    ]) {
      if (json.containsKey(key)) {
        source[key] = json[key];
      }
    }
    return source.isEmpty
        ? OutcomeProfessionalFeedbackModel.empty
        : OutcomeProfessionalFeedbackModel.fromJson(source);
  }

  static DebriefModel _readDebrief(Object? value) {
    if (value is Map<String, dynamic>) {
      return DebriefModel.fromJson(value);
    }
    return DebriefModel.empty;
  }

  static String _readOptionalString(Object? value) {
    return _readNullableString(value) ?? '';
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }
}
