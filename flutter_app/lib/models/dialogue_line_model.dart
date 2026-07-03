import 'relationship_score_model.dart';
import 'audio_config_model.dart';

class DialogueLineModel {
  final String speaker;
  final String text;
  final String emotion;
  final String? characterId;
  final String? characterImage;
  final String? soundEffect;
  final String? voiceClip;
  final String? subtitle;
  final AudioConfigModel audio;
  final List<String> requiredStoryFlags;
  final List<String> blockedByStoryFlags;
  final RelationshipScoreModel? requiredRelationshipMinimums;

  const DialogueLineModel({
    required this.speaker,
    required this.text,
    this.emotion = 'neutral',
    this.characterId,
    this.characterImage,
    this.soundEffect,
    this.voiceClip,
    this.subtitle,
    this.audio = AudioConfigModel.empty,
    this.requiredStoryFlags = const <String>[],
    this.blockedByStoryFlags = const <String>[],
    this.requiredRelationshipMinimums,
  });

  factory DialogueLineModel.fromJson(Map<String, dynamic> json) {
    return DialogueLineModel(
      speaker: _readString(json['speaker'], fallback: 'Narrator'),
      text: _readString(json['text'], fallback: _readString(json['dialogue'])),
      emotion: _readString(json['emotion'], fallback: 'neutral'),
      characterId: _readNullableString(json['characterId'] ?? json['speakerCharacterId']),
      characterImage: _readNullableString(json['characterImage']),
      soundEffect: _readNullableString(json['soundEffect']),
      voiceClip: _readNullableString(json['voiceClip'] ?? json['voice'] ?? json['voiceOver']),
      subtitle: _readNullableString(json['subtitle'] ?? json['caption']),
      audio: AudioConfigModel.fromJson(json['audio']),
      requiredStoryFlags: _readStringList(json['requiredStoryFlags'] ?? json['visibleWhenFlags']),
      blockedByStoryFlags: _readStringList(json['blockedByStoryFlags'] ?? json['hiddenByFlags']),
      requiredRelationshipMinimums: _readRelationship(json['requiredRelationshipMinimums']),
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
  }

  static RelationshipScoreModel? _readRelationship(Object? value) {
    if (value is Map<String, dynamic>) {
      return RelationshipScoreModel.fromJson(value);
    }
    return null;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String? _readNullableString(Object? value) {
    final text = _readString(value);
    return text.isEmpty ? null : text;
  }
}
