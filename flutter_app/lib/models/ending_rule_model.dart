import 'relationship_score_model.dart';
import 'score_model.dart';

class EndingRuleModel {
  final String id;
  final String title;
  final String description;
  final List<String> requiredStoryFlags;
  final List<String> blockedByStoryFlags;
  final List<String> requiredConsequenceFlags;
  final List<String> blockedByConsequenceFlags;
  final ScoreModel? requiredScoreMinimums;
  final RelationshipScoreModel? requiredRelationshipMinimums;
  final int priority;

  const EndingRuleModel({
    required this.id,
    required this.title,
    this.description = '',
    this.requiredStoryFlags = const <String>[],
    this.blockedByStoryFlags = const <String>[],
    this.requiredConsequenceFlags = const <String>[],
    this.blockedByConsequenceFlags = const <String>[],
    this.requiredScoreMinimums,
    this.requiredRelationshipMinimums,
    this.priority = 0,
  });

  factory EndingRuleModel.fromJson(Map<String, dynamic> json) {
    return EndingRuleModel(
      id: _readString(json['id'], fallback: 'ending'),
      title: _readString(json['title'], fallback: 'Role Ending'),
      description: _readString(json['description']),
      requiredStoryFlags: _readStringList(json['requiredStoryFlags']),
      blockedByStoryFlags: _readStringList(json['blockedByStoryFlags']),
      requiredConsequenceFlags: _readStringList(json['requiredConsequenceFlags']),
      blockedByConsequenceFlags: _readStringList(json['blockedByConsequenceFlags']),
      requiredScoreMinimums: _readScore(json['requiredScoreMinimums']),
      requiredRelationshipMinimums: _readRelationship(json['requiredRelationshipMinimums']),
      priority: _readInt(json['priority']),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return 0;
  }

  static ScoreModel? _readScore(Object? value) {
    if (value is Map<String, dynamic>) {
      return ScoreModel.fromJson(value);
    }
    return null;
  }

  static RelationshipScoreModel? _readRelationship(Object? value) {
    if (value is Map<String, dynamic>) {
      return RelationshipScoreModel.fromJson(value);
    }
    return null;
  }
}
