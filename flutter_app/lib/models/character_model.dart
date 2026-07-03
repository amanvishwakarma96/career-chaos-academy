class CharacterModel {
  final String id;
  final String displayName;
  final String role;
  final String archetype;
  final String defaultEmotion;
  final String defaultImage;
  final Map<String, String> expressions;
  final List<String> aliases;
  final List<String> personalityTraits;
  final String dialogueStyle;

  const CharacterModel({
    required this.id,
    required this.displayName,
    this.role = '',
    this.archetype = 'supporting',
    this.defaultEmotion = 'neutral',
    this.defaultImage = '',
    this.expressions = const <String, String>{},
    this.aliases = const <String>[],
    this.personalityTraits = const <String>[],
    this.dialogueStyle = '',
  });

  bool get isMentor => archetype.toLowerCase().contains('mentor');
  bool get isVillain => archetype.toLowerCase().contains('villain');

  String? expressionFor(String emotion) {
    final normalizedEmotion = _normalize(emotion);
    final mapped = expressions[normalizedEmotion];
    if (mapped != null && mapped.trim().isNotEmpty) {
      return mapped;
    }

    final defaultMapped = expressions[_normalize(defaultEmotion)];
    if (defaultMapped != null && defaultMapped.trim().isNotEmpty) {
      return defaultMapped;
    }

    return defaultImage.trim().isEmpty ? null : defaultImage.trim();
  }

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: _readString(json['id'], fallback: 'unknown_character'),
      displayName: _readString(
        json['displayName'],
        fallback: _readString(json['name'], fallback: 'Unknown Character'),
      ),
      role: _readString(json['role']),
      archetype: _readString(json['archetype'], fallback: 'supporting'),
      defaultEmotion: _readString(json['defaultEmotion'], fallback: 'neutral'),
      defaultImage: _readString(json['defaultImage']),
      expressions: _readExpressionMap(json['expressions'] ?? json['expressionMap']),
      aliases: _readStringList(json['aliases']),
      personalityTraits: _readStringList(json['personalityTraits']),
      dialogueStyle: _readString(json['dialogueStyle']),
    );
  }

  static Map<String, String> _readExpressionMap(Object? value) {
    if (value is! Map) {
      return const <String, String>{};
    }

    final output = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final item = entry.value;
      if (key is String && item is String && item.trim().isNotEmpty) {
        output[_normalize(key)] = item.trim();
      }
    }
    return Map<String, String>.unmodifiable(output);
  }

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

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }
}
