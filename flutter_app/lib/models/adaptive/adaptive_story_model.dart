import '../dialogue_line_model.dart';
import 'user_behavior_summary_model.dart';

class AdaptiveDialogueInjectionModel {
  final String id;
  final String speaker;
  final String text;
  final String emotion;
  final String? characterId;
  final List<String> requiredBehaviorPatterns;
  final List<String> blockedBehaviorPatterns;
  final int priority;

  const AdaptiveDialogueInjectionModel({
    required this.id,
    required this.speaker,
    required this.text,
    this.emotion = 'thoughtful',
    this.characterId,
    this.requiredBehaviorPatterns = const <String>[],
    this.blockedBehaviorPatterns = const <String>[],
    this.priority = 0,
  });

  factory AdaptiveDialogueInjectionModel.fromJson(Map<String, dynamic> json) {
    return AdaptiveDialogueInjectionModel(
      id: _readString(json['id']),
      speaker: _readString(json['speaker'], fallback: 'Mentor'),
      text: _readString(json['text'] ?? json['dialogue']),
      emotion: _readString(json['emotion'], fallback: 'thoughtful'),
      characterId: _readNullableString(json['characterId']),
      requiredBehaviorPatterns: _readStringList(json['requiredBehaviorPatterns']),
      blockedBehaviorPatterns: _readStringList(json['blockedBehaviorPatterns']),
      priority: _readInt(json['priority']),
    );
  }

  bool isVisibleFor(UserBehaviorSummaryModel summary) {
    final hasRequired = requiredBehaviorPatterns.isEmpty ||
        requiredBehaviorPatterns.every(summary.hasPattern);
    final isBlocked = blockedBehaviorPatterns.any(summary.hasPattern);
    return hasRequired && !isBlocked && text.isNotEmpty;
  }

  DialogueLineModel toDialogueLine() {
    return DialogueLineModel(
      speaker: speaker,
      text: text,
      emotion: emotion,
      characterId: characterId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'speaker': speaker,
        'text': text,
        'emotion': emotion,
        if (characterId != null) 'characterId': characterId,
        'requiredBehaviorPatterns': requiredBehaviorPatterns,
        'blockedBehaviorPatterns': blockedBehaviorPatterns,
        'priority': priority,
      };
}

class AdaptiveDifficultyConfigModel {
  final String baseLevel;
  final String easierLevel;
  final String harderLevel;
  final List<String> increaseWhenPatterns;
  final List<String> decreaseWhenPatterns;

  const AdaptiveDifficultyConfigModel({
    this.baseLevel = 'normal',
    this.easierLevel = 'guided',
    this.harderLevel = 'advanced',
    this.increaseWhenPatterns = const <String>[],
    this.decreaseWhenPatterns = const <String>[],
  });

  static const defaults = AdaptiveDifficultyConfigModel();

  factory AdaptiveDifficultyConfigModel.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return defaults;
    return AdaptiveDifficultyConfigModel(
      baseLevel: _readString(value['baseLevel'], fallback: 'normal'),
      easierLevel: _readString(value['easierLevel'], fallback: 'guided'),
      harderLevel: _readString(value['harderLevel'], fallback: 'advanced'),
      increaseWhenPatterns: _readStringList(value['increaseWhenPatterns']),
      decreaseWhenPatterns: _readStringList(value['decreaseWhenPatterns']),
    );
  }

  String resolve(UserBehaviorSummaryModel summary) {
    if (decreaseWhenPatterns.any(summary.hasPattern)) return easierLevel;
    if (increaseWhenPatterns.any(summary.hasPattern)) return harderLevel;
    if (summary.hasPattern('repeated_failures')) return easierLevel;
    if (summary.hasPattern('high_performer')) return harderLevel;
    return baseLevel;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'baseLevel': baseLevel,
        'easierLevel': easierLevel,
        'harderLevel': harderLevel,
        'increaseWhenPatterns': increaseWhenPatterns,
        'decreaseWhenPatterns': decreaseWhenPatterns,
      };
}

class AdaptiveStoryRecommendationModel {
  final String roleId;
  final String? chapterId;
  final String reason;
  final String suggestedActivityType;
  final String difficulty;
  final bool shouldGenerateSideMission;

  const AdaptiveStoryRecommendationModel({
    required this.roleId,
    this.chapterId,
    required this.reason,
    this.suggestedActivityType = '',
    this.difficulty = 'normal',
    this.shouldGenerateSideMission = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'roleId': roleId,
        if (chapterId != null) 'chapterId': chapterId,
        'reason': reason,
        'suggestedActivityType': suggestedActivityType,
        'difficulty': difficulty,
        'shouldGenerateSideMission': shouldGenerateSideMission,
      };
}

class AdaptiveStoryDraftModel {
  final String id;
  final String roleId;
  final String title;
  final String status;
  final String safetyStatus;
  final String promptVersion;
  final Map<String, dynamic> generatedJson;
  final DateTime createdAt;

  const AdaptiveStoryDraftModel({
    required this.id,
    required this.roleId,
    required this.title,
    this.status = 'draft_pending_admin_review',
    this.safetyStatus = 'requires_professional_safety_review',
    this.promptVersion = 'adaptive_story_v1',
    this.generatedJson = const <String, dynamic>{},
    required this.createdAt,
  });

  factory AdaptiveStoryDraftModel.fromJson(Map<String, dynamic> json) {
    return AdaptiveStoryDraftModel(
      id: _readString(json['id']),
      roleId: _readString(json['roleId']),
      title: _readString(json['title'], fallback: 'Adaptive Side Mission Draft'),
      status: _readString(json['status'], fallback: 'draft_pending_admin_review'),
      safetyStatus: _readString(json['safetyStatus'], fallback: 'requires_professional_safety_review'),
      promptVersion: _readString(json['promptVersion'], fallback: 'adaptive_story_v1'),
      generatedJson: json['generatedJson'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['generatedJson'] as Map<String, dynamic>)
          : const <String, dynamic>{},
      createdAt: DateTime.tryParse(_readString(json['createdAt'])) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'roleId': roleId,
        'title': title,
        'status': status,
        'safetyStatus': safetyStatus,
        'promptVersion': promptVersion,
        'generatedJson': generatedJson,
        'createdAt': createdAt.toIso8601String(),
      };
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

String? _readNullableString(Object? value) {
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
}
