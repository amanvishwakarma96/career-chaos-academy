import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/voice_profile_model.dart';
import 'api_client.dart';

class VoiceConversationService {
  VoiceConversationService._();

  static final VoiceConversationService instance = VoiceConversationService._();
  static const String _profileAssetPath = 'assets/game/voice/voice_profiles.json';
  static const String _settingsPrefix = 'career_chaos_voice_settings_';
  static const String _turnsPrefix = 'career_chaos_character_turns_';

  Future<VoiceProfileCatalogModel> loadProfiles() async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/voice/profiles');
        return VoiceProfileCatalogModel.fromJson(json);
      } on Object {
        // Offline fallback keeps the prototype usable without backend.
      }
    }
    final raw = await rootBundle.loadString(_profileAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const VoiceConversationServiceException('Voice profile catalog is invalid.');
    }
    return VoiceProfileCatalogModel.fromJson(decoded);
  }

  Future<VoiceSettingsModel> loadSettings(String userId) async {
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.getMap('/api/users/${Uri.encodeComponent(userId)}/voice-settings');
        final settingsJson = json['settings'];
        if (settingsJson is Map<String, dynamic>) return VoiceSettingsModel.fromJson(settingsJson);
      } on Object {
        // Fallback to local settings.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_settingsPrefix$userId');
    if (raw == null || raw.trim().isEmpty) return const VoiceSettingsModel();
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? VoiceSettingsModel.fromJson(decoded) : const VoiceSettingsModel();
  }

  Future<VoiceSettingsModel> saveSettings(String userId, VoiceSettingsModel settings) async {
    final stamped = settings.copyWith(updatedAt: DateTime.now().toIso8601String());
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap(
          '/api/users/${Uri.encodeComponent(userId)}/voice-settings',
          stamped.toJson(),
        );
        final settingsJson = json['settings'];
        if (settingsJson is Map<String, dynamic>) return VoiceSettingsModel.fromJson(settingsJson);
      } on Object {
        // Fallback to local settings.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_settingsPrefix$userId', jsonEncode(stamped.toJson()));
    return stamped;
  }

  Future<CharacterChatResponseModel> sendCharacterMessage({
    required String userId,
    required VoiceSettingsModel settings,
    required VoiceProfileModel profile,
    required String message,
    String roleId = 'developer',
    String scenarioId = 'prototype_scenario',
    String scenarioTitle = 'Career Chaos voice prototype',
  }) async {
    final safeMessage = message.trim();
    if (safeMessage.isEmpty) {
      throw const VoiceConversationServiceException('Type a message before asking the character.');
    }
    if (ApiClient.instance.isEnabled) {
      try {
        final json = await ApiClient.instance.postMap('/api/voice/character-chat', <String, dynamic>{
          'userId': userId,
          'characterId': profile.characterId,
          'message': safeMessage,
          'languageMode': settings.languageMode,
          'voiceSettings': settings.toJson(),
          'scenarioContext': <String, dynamic>{
            'roleId': roleId,
            'scenarioId': scenarioId,
            'scenarioTitle': scenarioTitle,
          },
        });
        return CharacterChatResponseModel.fromJson(json);
      } on Object {
        // Fallback to local safe prototype response.
      }
    }
    final response = _localCharacterReply(
      userId: userId,
      profile: profile,
      settings: settings,
      message: safeMessage,
      roleId: roleId,
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
    );
    await _saveLocalTurn(userId, response.turn);
    return response;
  }

  Future<List<CharacterChatTurnModel>> loadLocalTurns(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_turnsPrefix$userId');
    if (raw == null || raw.trim().isEmpty) return const <CharacterChatTurnModel>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <CharacterChatTurnModel>[];
    return decoded.whereType<Map<String, dynamic>>().map(CharacterChatTurnModel.fromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> synthesizePlaceholder({
    required String text,
    required VoiceSettingsModel settings,
  }) async {
    if (ApiClient.instance.isEnabled) {
      try {
        return await ApiClient.instance.postMap('/api/voice/tts-placeholder', <String, dynamic>{
          'text': text,
          'languageMode': settings.languageMode,
          'voiceProfileId': settings.selectedVoiceProfileId,
        });
      } on Object {
        // Local placeholder below.
      }
    }
    return <String, dynamic>{
      'status': 'placeholder',
      'provider': 'text_to_speech_placeholder',
      'audioUrl': null,
      'subtitles': <String>[text],
      'fallbackToText': true,
    };
  }

  CharacterChatResponseModel _localCharacterReply({
    required String userId,
    required VoiceProfileModel profile,
    required VoiceSettingsModel settings,
    required String message,
    required String roleId,
    required String scenarioId,
    required String scenarioTitle,
  }) {
    final unsafe = _containsUnsafe(message);
    final reply = unsafe
        ? _blockedReply(settings.languageMode)
        : _scenarioBoundReply(
            languageMode: settings.languageMode,
            characterName: profile.displayName,
            scenarioTitle: scenarioTitle,
            message: message,
          );
    final now = DateTime.now().toIso8601String();
    final turn = CharacterChatTurnModel(
      id: 'voice_turn_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      characterId: profile.characterId,
      characterName: profile.displayName,
      roleId: roleId,
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      languageMode: settings.languageMode,
      inputText: message,
      replyText: reply,
      subtitles: <String>[reply],
      voiceEnabled: settings.voiceEnabled,
      fallbackToText: true,
      safety: ConversationSafetyResultModel(
        status: unsafe ? 'blocked' : 'safe',
        blocked: unsafe,
        reason: unsafe ? 'unsafe_advice_filter' : 'scenario_context_ok',
      ),
      memoryBoundary: const CharacterMemoryBoundaryModel(
        scenarioBound: true,
        noPersistentPersonalMemory: true,
        allowedContext: <String>['roleId', 'scenarioId', 'scenarioTitle', 'currentUserMessage'],
        notice: 'Character memory is limited to this scenario turn. Personal memory is not stored by this prototype.',
      ),
      createdAt: now,
    );
    return CharacterChatResponseModel(
      turn: turn,
      profile: profile,
      languageLabel: _languageLabel(settings.languageMode),
      fallbackToText: true,
      subtitlesAlwaysOn: true,
    );
  }

  Future<void> _saveLocalTurn(String userId, CharacterChatTurnModel turn) async {
    final existing = await loadLocalTurns(userId);
    final updated = <CharacterChatTurnModel>[turn, ...existing].take(40).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_turnsPrefix$userId',
      jsonEncode(updated.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  bool _containsUnsafe(String value) {
    final text = value.toLowerCase();
    const unsafe = <String>[
      'prescribe',
      'dosage',
      'self harm',
      'suicide',
      'hide evidence',
      'delete logs',
      'bypass safety',
      'steal data',
      'fake certificate',
      'medical diagnosis',
    ];
    return unsafe.any((item) => text.contains(item));
  }

  String _scenarioBoundReply({
    required String languageMode,
    required String characterName,
    required String scenarioTitle,
    required String message,
  }) {
    final clipped = message.length > 80 ? '${message.substring(0, 80)}…' : message;
    if (languageMode == 'hindi') {
      return '$characterName: मैं सिर्फ इस scenario ($scenarioTitle) के context में guide कर सकता/सकती हूँ. "$clipped" के लिए evidence check करें, stakeholder को update दें, और unsafe shortcut avoid करें.';
    }
    if (languageMode == 'hinglish') {
      return '$characterName: Main sirf is scenario ($scenarioTitle) ke context mein help karunga. "$clipped" ke liye evidence check karo, stakeholder ko update do, aur unsafe shortcut avoid karo.';
    }
    return '$characterName: I will stay inside this scenario ($scenarioTitle). For "$clipped", verify evidence, communicate the risk, and avoid shortcuts that create safety, privacy, or ethics issues.';
  }

  String _blockedReply(String languageMode) {
    if (languageMode == 'hindi') {
      return 'मैं unsafe या professional boundary तोड़ने वाली सलाह नहीं दे सकता/सकती. Safe learning path चुनें: evidence collect करें, senior/trainer को escalate करें, और policy follow करें.';
    }
    if (languageMode == 'hinglish') {
      return 'Main unsafe ya professional boundary todne wali advice nahi de sakta. Safe learning path choose karo: evidence collect karo, senior/trainer ko escalate karo, aur policy follow karo.';
    }
    return 'I cannot provide unsafe advice or guidance that breaks professional boundaries. Use the safe learning path: collect evidence, escalate to the right senior/trainer, and follow policy.';
  }

  String _languageLabel(String value) {
    if (value == 'hindi') return 'Hindi';
    if (value == 'hinglish') return 'Hinglish';
    return 'English';
  }
}

class VoiceConversationServiceException implements Exception {
  final String message;
  const VoiceConversationServiceException(this.message);

  @override
  String toString() => message;
}
