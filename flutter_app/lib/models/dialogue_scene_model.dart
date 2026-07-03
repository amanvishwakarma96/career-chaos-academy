import 'dialogue_line_model.dart';
import 'audio_config_model.dart';

class DialogueSceneModel {
  final String id;
  final String title;
  final String? backgroundImage;
  final String? characterId;
  final String? characterImage;
  final String? soundEffect;
  final AudioConfigModel audio;
  final String transitionType;
  final List<DialogueLineModel> dialogues;

  const DialogueSceneModel({
    required this.id,
    this.title = '',
    this.backgroundImage,
    this.characterId,
    this.characterImage,
    this.soundEffect,
    this.audio = AudioConfigModel.empty,
    this.transitionType = 'fade',
    this.dialogues = const <DialogueLineModel>[],
  });

  bool get hasDialogues => dialogues.isNotEmpty;

  factory DialogueSceneModel.fromJson(Map<String, dynamic> json) {
    return DialogueSceneModel(
      id: _readString(json['id'], fallback: 'scene'),
      title: _readString(json['title']),
      backgroundImage: _readNullableString(json['backgroundImage']),
      characterId: _readNullableString(json['characterId'] ?? json['speakerCharacterId']),
      characterImage: _readNullableString(json['characterImage']),
      soundEffect: _readNullableString(json['soundEffect']),
      audio: AudioConfigModel.fromJson(json['audio']),
      transitionType: _readString(json['transitionType'], fallback: 'fade'),
      dialogues: _readDialogues(json['dialogues']),
    );
  }

  static List<DialogueLineModel> _readDialogues(Object? value) {
    if (value is! List) {
      return const <DialogueLineModel>[];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(DialogueLineModel.fromJson)
        .where((line) => line.text.isNotEmpty)
        .toList(growable: false);
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
