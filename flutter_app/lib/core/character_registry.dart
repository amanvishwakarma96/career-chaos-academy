import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/character_model.dart';

class CharacterRegistry {
  final Map<String, CharacterModel> _charactersById;
  final Map<String, String> _aliasToId;

  static const String defaultAssetPath = 'assets/game/characters/characters.json';

  static final CharacterRegistry empty = CharacterRegistry._(
    const <String, CharacterModel>{},
    const <String, String>{},
  );

  const CharacterRegistry._(this._charactersById, this._aliasToId);

  bool get isEmpty => _charactersById.isEmpty;
  bool get isNotEmpty => _charactersById.isNotEmpty;
  List<CharacterModel> get characters =>
      _charactersById.values.toList(growable: false);

  CharacterModel? findById(String? id) {
    final normalized = _normalize(id);
    if (normalized == null) {
      return null;
    }
    return _charactersById[normalized];
  }

  CharacterModel? findBySpeaker(String? speaker) {
    final normalized = _normalize(speaker);
    if (normalized == null || normalized == 'you') {
      return null;
    }
    final id = _aliasToId[normalized] ?? normalized;
    return _charactersById[id];
  }

  CharacterModel? findForDialogue({
    String? characterId,
    required String speaker,
  }) {
    return findById(characterId) ?? findBySpeaker(speaker);
  }

  String displayNameFor({
    String? characterId,
    required String fallbackSpeaker,
  }) {
    return findForDialogue(
          characterId: characterId,
          speaker: fallbackSpeaker,
        )
            ?.displayName ??
        fallbackSpeaker;
  }

  static Future<CharacterRegistry> loadFromAssets({
    String assetPath = defaultAssetPath,
  }) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      return CharacterRegistry.fromJson(decoded);
    } catch (_) {
      // Character metadata should enrich scenes, never block gameplay.
      return CharacterRegistry.empty;
    }
  }

  factory CharacterRegistry.fromJson(Object? json) {
    final items = _readCharacterItems(json);
    final characters = <String, CharacterModel>{};
    final aliases = <String, String>{};

    for (final item in items) {
      final character = CharacterModel.fromJson(item);
      final normalizedId = _normalize(character.id);
      if (normalizedId == null) {
        continue;
      }

      characters[normalizedId] = character;
      aliases[_normalizeRequired(character.displayName)] = normalizedId;
      aliases[normalizedId] = normalizedId;

      for (final alias in character.aliases) {
        aliases[_normalizeRequired(alias)] = normalizedId;
      }
    }

    return CharacterRegistry._(
      Map<String, CharacterModel>.unmodifiable(characters),
      Map<String, String>.unmodifiable(aliases),
    );
  }

  static List<Map<String, dynamic>> _readCharacterItems(Object? json) {
    if (json is List) {
      return json
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (json is Map) {
      final characters = json['characters'];
      if (characters is List) {
        return characters
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    }
    return const <Map<String, dynamic>>[];
  }

  static String? _normalize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return _normalizeRequired(value);
  }

  static String _normalizeRequired(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }
}
