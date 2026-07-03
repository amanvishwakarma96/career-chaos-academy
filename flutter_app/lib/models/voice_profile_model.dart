class VoiceProfileCatalogModel {
  final int version;
  final bool subtitleFirst;
  final List<String> supportedLanguages;
  final List<VoiceProfileModel> profiles;
  final VoiceIntegrationPlaceholderModel textToSpeech;
  final VoiceIntegrationPlaceholderModel speechToText;
  final CharacterMemoryBoundaryModel conversationSafety;

  const VoiceProfileCatalogModel({
    required this.version,
    required this.subtitleFirst,
    required this.supportedLanguages,
    required this.profiles,
    required this.textToSpeech,
    required this.speechToText,
    required this.conversationSafety,
  });

  factory VoiceProfileCatalogModel.fromJson(Map<String, dynamic> json) {
    return VoiceProfileCatalogModel(
      version: _readInt(json['version'], fallback: 1),
      subtitleFirst: json['subtitleFirst'] != false,
      supportedLanguages: _readStringList(json['supportedLanguages']),
      profiles: _readMapList(json['profiles']).map(VoiceProfileModel.fromJson).toList(growable: false),
      textToSpeech: VoiceIntegrationPlaceholderModel.fromJson(_readMap(json['textToSpeech'])),
      speechToText: VoiceIntegrationPlaceholderModel.fromJson(_readMap(json['speechToText'])),
      conversationSafety: CharacterMemoryBoundaryModel.fromJson(_readMap(json['conversationSafety'])),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'subtitleFirst': subtitleFirst,
        'supportedLanguages': supportedLanguages,
        'profiles': profiles.map((item) => item.toJson()).toList(growable: false),
        'textToSpeech': textToSpeech.toJson(),
        'speechToText': speechToText.toJson(),
        'conversationSafety': conversationSafety.toJson(),
      };
}

class VoiceProfileModel {
  final String id;
  final String characterId;
  final String displayName;
  final String roleId;
  final String tone;
  final String defaultLanguage;
  final List<String> languageModes;
  final bool voiceEnabledByDefault;
  final bool subtitlesAlwaysOn;
  final String ttsProvider;
  final String sttProvider;
  final bool fallbackToText;
  final String sampleSubtitle;
  final CharacterMemoryBoundaryModel memoryPolicy;

  const VoiceProfileModel({
    required this.id,
    required this.characterId,
    required this.displayName,
    required this.roleId,
    required this.tone,
    required this.defaultLanguage,
    required this.languageModes,
    required this.voiceEnabledByDefault,
    required this.subtitlesAlwaysOn,
    required this.ttsProvider,
    required this.sttProvider,
    required this.fallbackToText,
    required this.sampleSubtitle,
    required this.memoryPolicy,
  });

  factory VoiceProfileModel.fromJson(Map<String, dynamic> json) {
    return VoiceProfileModel(
      id: _readString(json['id']),
      characterId: _readString(json['characterId']),
      displayName: _readString(json['displayName'], fallback: 'Career Chaos Character'),
      roleId: _readString(json['roleId'], fallback: 'developer'),
      tone: _readString(json['tone'], fallback: 'professional'),
      defaultLanguage: _normalizeLanguage(_readString(json['defaultLanguage'], fallback: 'english')),
      languageModes: _readStringList(json['languageModes']).isEmpty
          ? const <String>['english', 'hinglish', 'hindi']
          : _readStringList(json['languageModes']).map(_normalizeLanguage).toList(growable: false),
      voiceEnabledByDefault: json['voiceEnabledByDefault'] == true,
      subtitlesAlwaysOn: json['subtitlesAlwaysOn'] != false,
      ttsProvider: _readString(json['ttsProvider'], fallback: 'placeholder'),
      sttProvider: _readString(json['sttProvider'], fallback: 'placeholder'),
      fallbackToText: json['fallbackToText'] != false,
      sampleSubtitle: _readString(json['sampleSubtitle']),
      memoryPolicy: CharacterMemoryBoundaryModel.fromJson(_readMap(json['memoryPolicy'])),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'characterId': characterId,
        'displayName': displayName,
        'roleId': roleId,
        'tone': tone,
        'defaultLanguage': defaultLanguage,
        'languageModes': languageModes,
        'voiceEnabledByDefault': voiceEnabledByDefault,
        'subtitlesAlwaysOn': subtitlesAlwaysOn,
        'ttsProvider': ttsProvider,
        'sttProvider': sttProvider,
        'fallbackToText': fallbackToText,
        'sampleSubtitle': sampleSubtitle,
        'memoryPolicy': memoryPolicy.toJson(),
      };
}

class VoiceSettingsModel {
  final bool voiceEnabled;
  final bool subtitlesAlwaysOn;
  final String languageMode;
  final String textToSpeechProvider;
  final String speechToTextProvider;
  final bool fallbackToText;
  final double voiceVolume;
  final String selectedVoiceProfileId;
  final String? updatedAt;

  const VoiceSettingsModel({
    this.voiceEnabled = false,
    this.subtitlesAlwaysOn = true,
    this.languageMode = 'english',
    this.textToSpeechProvider = 'placeholder',
    this.speechToTextProvider = 'placeholder',
    this.fallbackToText = true,
    this.voiceVolume = 0.75,
    this.selectedVoiceProfileId = 'senior_dev_mentor_voice',
    this.updatedAt,
  });

  factory VoiceSettingsModel.fromJson(Map<String, dynamic> json) {
    return VoiceSettingsModel(
      voiceEnabled: json['voiceEnabled'] == true,
      subtitlesAlwaysOn: json['subtitlesAlwaysOn'] != false,
      languageMode: _normalizeLanguage(_readString(json['languageMode'], fallback: 'english')),
      textToSpeechProvider: _readString(json['textToSpeechProvider'], fallback: 'placeholder'),
      speechToTextProvider: _readString(json['speechToTextProvider'], fallback: 'placeholder'),
      fallbackToText: json['fallbackToText'] != false,
      voiceVolume: _readDouble(json['voiceVolume'], fallback: 0.75).clamp(0, 1).toDouble(),
      selectedVoiceProfileId: _readString(json['selectedVoiceProfileId'], fallback: 'senior_dev_mentor_voice'),
      updatedAt: _readNullableString(json['updatedAt']),
    );
  }

  VoiceSettingsModel copyWith({
    bool? voiceEnabled,
    bool? subtitlesAlwaysOn,
    String? languageMode,
    String? textToSpeechProvider,
    String? speechToTextProvider,
    bool? fallbackToText,
    double? voiceVolume,
    String? selectedVoiceProfileId,
    String? updatedAt,
  }) {
    return VoiceSettingsModel(
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      subtitlesAlwaysOn: subtitlesAlwaysOn ?? this.subtitlesAlwaysOn,
      languageMode: languageMode == null ? this.languageMode : _normalizeLanguage(languageMode),
      textToSpeechProvider: textToSpeechProvider ?? this.textToSpeechProvider,
      speechToTextProvider: speechToTextProvider ?? this.speechToTextProvider,
      fallbackToText: fallbackToText ?? this.fallbackToText,
      voiceVolume: (voiceVolume ?? this.voiceVolume).clamp(0, 1).toDouble(),
      selectedVoiceProfileId: selectedVoiceProfileId ?? this.selectedVoiceProfileId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'voiceEnabled': voiceEnabled,
        'subtitlesAlwaysOn': subtitlesAlwaysOn,
        'languageMode': languageMode,
        'textToSpeechProvider': textToSpeechProvider,
        'speechToTextProvider': speechToTextProvider,
        'fallbackToText': fallbackToText,
        'voiceVolume': voiceVolume,
        'selectedVoiceProfileId': selectedVoiceProfileId,
        'updatedAt': updatedAt,
      };
}

class CharacterChatTurnModel {
  final String id;
  final String userId;
  final String characterId;
  final String characterName;
  final String roleId;
  final String scenarioId;
  final String scenarioTitle;
  final String languageMode;
  final String inputText;
  final String replyText;
  final List<String> subtitles;
  final bool voiceEnabled;
  final bool fallbackToText;
  final ConversationSafetyResultModel safety;
  final CharacterMemoryBoundaryModel memoryBoundary;
  final String createdAt;

  const CharacterChatTurnModel({
    required this.id,
    required this.userId,
    required this.characterId,
    required this.characterName,
    required this.roleId,
    required this.scenarioId,
    required this.scenarioTitle,
    required this.languageMode,
    required this.inputText,
    required this.replyText,
    required this.subtitles,
    required this.voiceEnabled,
    required this.fallbackToText,
    required this.safety,
    required this.memoryBoundary,
    required this.createdAt,
  });

  factory CharacterChatTurnModel.fromJson(Map<String, dynamic> json) {
    final voice = _readMap(json['voice']);
    return CharacterChatTurnModel(
      id: _readString(json['id']),
      userId: _readString(json['userId'], fallback: 'local-user'),
      characterId: _readString(json['characterId'], fallback: 'senior_dev_mentor'),
      characterName: _readString(json['characterName'], fallback: 'Career Chaos Character'),
      roleId: _readString(json['roleId'], fallback: 'developer'),
      scenarioId: _readString(json['scenarioId'], fallback: 'prototype_scenario'),
      scenarioTitle: _readString(json['scenarioTitle'], fallback: 'Career Chaos practice scenario'),
      languageMode: _normalizeLanguage(_readString(json['languageMode'], fallback: 'english')),
      inputText: _readString(json['inputText']),
      replyText: _readString(json['replyText']),
      subtitles: _readStringList(json['subtitles']).isEmpty ? <String>[_readString(json['replyText'])] : _readStringList(json['subtitles']),
      voiceEnabled: voice['enabled'] == true,
      fallbackToText: voice['fallbackToText'] != false,
      safety: ConversationSafetyResultModel.fromJson(_readMap(json['safety'])),
      memoryBoundary: CharacterMemoryBoundaryModel.fromJson(_readMap(json['memoryBoundary'])),
      createdAt: _readString(json['createdAt'], fallback: DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'userId': userId,
        'characterId': characterId,
        'characterName': characterName,
        'roleId': roleId,
        'scenarioId': scenarioId,
        'scenarioTitle': scenarioTitle,
        'languageMode': languageMode,
        'inputText': inputText,
        'replyText': replyText,
        'subtitles': subtitles,
        'voice': <String, dynamic>{'enabled': voiceEnabled, 'fallbackToText': fallbackToText},
        'safety': safety.toJson(),
        'memoryBoundary': memoryBoundary.toJson(),
        'createdAt': createdAt,
      };
}

class CharacterChatResponseModel {
  final CharacterChatTurnModel turn;
  final VoiceProfileModel? profile;
  final String languageLabel;
  final bool fallbackToText;
  final bool subtitlesAlwaysOn;

  const CharacterChatResponseModel({
    required this.turn,
    required this.profile,
    required this.languageLabel,
    required this.fallbackToText,
    required this.subtitlesAlwaysOn,
  });

  factory CharacterChatResponseModel.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    return CharacterChatResponseModel(
      turn: CharacterChatTurnModel.fromJson(_readMap(json['turn'])),
      profile: profileJson is Map<String, dynamic> && profileJson.isNotEmpty ? VoiceProfileModel.fromJson(profileJson) : null,
      languageLabel: _readString(json['languageLabel'], fallback: 'English'),
      fallbackToText: json['fallbackToText'] != false,
      subtitlesAlwaysOn: json['subtitlesAlwaysOn'] != false,
    );
  }
}

class VoiceIntegrationPlaceholderModel {
  final String provider;
  final String status;
  final bool fallbackToText;
  final String notes;

  const VoiceIntegrationPlaceholderModel({
    this.provider = 'placeholder',
    this.status = 'future_ready',
    this.fallbackToText = true,
    this.notes = '',
  });

  factory VoiceIntegrationPlaceholderModel.fromJson(Map<String, dynamic> json) {
    return VoiceIntegrationPlaceholderModel(
      provider: _readString(json['provider'], fallback: 'placeholder'),
      status: _readString(json['status'], fallback: 'future_ready'),
      fallbackToText: json['fallbackToText'] != false,
      notes: _readString(json['notes']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'provider': provider,
        'status': status,
        'fallbackToText': fallbackToText,
        'notes': notes,
      };
}

class ConversationSafetyResultModel {
  final String status;
  final bool blocked;
  final String reason;

  const ConversationSafetyResultModel({
    required this.status,
    required this.blocked,
    required this.reason,
  });

  factory ConversationSafetyResultModel.fromJson(Map<String, dynamic> json) {
    return ConversationSafetyResultModel(
      status: _readString(json['status'], fallback: 'safe'),
      blocked: json['blocked'] == true,
      reason: _readString(json['reason'], fallback: 'scenario_context_ok'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status,
        'blocked': blocked,
        'reason': reason,
      };
}

class CharacterMemoryBoundaryModel {
  final bool scenarioBound;
  final bool noPersistentPersonalMemory;
  final int maxTurnsRetained;
  final List<String> allowedContext;
  final List<String> allowedContextKeys;
  final List<String> blockedTopics;
  final String notice;

  const CharacterMemoryBoundaryModel({
    this.scenarioBound = true,
    this.noPersistentPersonalMemory = true,
    this.maxTurnsRetained = 20,
    this.allowedContext = const <String>[],
    this.allowedContextKeys = const <String>[],
    this.blockedTopics = const <String>[],
    this.notice = 'Character memory is limited to the active scenario turn.',
  });

  factory CharacterMemoryBoundaryModel.fromJson(Map<String, dynamic> json) {
    return CharacterMemoryBoundaryModel(
      scenarioBound: json['scenarioBound'] != false,
      noPersistentPersonalMemory: json['noPersistentPersonalMemory'] != false,
      maxTurnsRetained: _readInt(json['maxTurnsRetained'], fallback: 20),
      allowedContext: _readStringList(json['allowedContext']),
      allowedContextKeys: _readStringList(json['allowedContextKeys']),
      blockedTopics: _readStringList(json['blockedTopics']),
      notice: _readString(json['notice'], fallback: 'Character memory is limited to the active scenario turn.'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scenarioBound': scenarioBound,
        'noPersistentPersonalMemory': noPersistentPersonalMemory,
        'maxTurnsRetained': maxTurnsRetained,
        'allowedContext': allowedContext,
        'allowedContextKeys': allowedContextKeys,
        'blockedTopics': blockedTopics,
        'notice': notice,
      };
}

String _normalizeLanguage(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'hindi' || normalized == 'hinglish' || normalized == 'english') {
    return normalized;
  }
  return 'english';
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

String? _readNullableString(Object? value) {
  final text = _readString(value);
  return text.isEmpty ? null : text;
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return fallback;
}

double _readDouble(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return fallback;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), item));
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value.map(_readMap).where((item) => item.isNotEmpty).toList(growable: false);
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().map((item) => item.trim()).where((item) => item.isNotEmpty).toList(growable: false);
}
