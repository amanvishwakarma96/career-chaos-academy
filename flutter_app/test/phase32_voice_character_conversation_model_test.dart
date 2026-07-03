import 'package:flutter_test/flutter_test.dart';
import 'package:career_chaos_academy/models/voice_profile_model.dart';

void main() {
  test('Phase 32 voice profiles, settings, and chat turns parse JSON safely', () {
    final catalog = VoiceProfileCatalogModel.fromJson(<String, dynamic>{
      'version': 1,
      'subtitleFirst': true,
      'supportedLanguages': <String>['english', 'hinglish', 'hindi'],
      'textToSpeech': <String, dynamic>{
        'provider': 'placeholder',
        'status': 'future_ready',
        'fallbackToText': true,
      },
      'speechToText': <String, dynamic>{
        'provider': 'placeholder',
        'status': 'future_ready',
        'fallbackToText': true,
      },
      'conversationSafety': <String, dynamic>{
        'scenarioBound': true,
        'noPersistentPersonalMemory': true,
        'blockedTopics': <String>['hide evidence'],
      },
      'profiles': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'senior_dev_mentor_voice',
          'characterId': 'senior_dev_mentor',
          'displayName': 'Senior Dev Mentor',
          'roleId': 'developer',
          'tone': 'calm',
          'defaultLanguage': 'english',
          'languageModes': <String>['english', 'hinglish', 'hindi'],
          'voiceEnabledByDefault': false,
          'subtitlesAlwaysOn': true,
          'ttsProvider': 'placeholder',
          'sttProvider': 'placeholder',
          'fallbackToText': true,
          'sampleSubtitle': 'Check evidence first.',
          'memoryPolicy': <String, dynamic>{
            'scenarioBound': true,
            'noPersistentPersonalMemory': true,
            'maxTurnsRetained': 20,
          },
        },
      ],
    });

    expect(catalog.subtitleFirst, isTrue);
    expect(catalog.supportedLanguages, contains('hinglish'));
    expect(catalog.profiles.single.subtitlesAlwaysOn, isTrue);
    expect(catalog.conversationSafety.scenarioBound, isTrue);

    final settings = VoiceSettingsModel.fromJson(<String, dynamic>{
      'voiceEnabled': true,
      'subtitlesAlwaysOn': true,
      'languageMode': 'hindi',
      'fallbackToText': true,
      'voiceVolume': 0.8,
      'selectedVoiceProfileId': 'senior_dev_mentor_voice',
    });
    expect(settings.voiceEnabled, isTrue);
    expect(settings.languageMode, 'hindi');
    expect(settings.fallbackToText, isTrue);

    final turn = CharacterChatTurnModel.fromJson(<String, dynamic>{
      'id': 'turn_1',
      'userId': 'user_1',
      'characterId': 'senior_dev_mentor',
      'characterName': 'Senior Dev Mentor',
      'roleId': 'developer',
      'scenarioId': 'interview_voice_prototype',
      'scenarioTitle': 'Interview voice practice prototype',
      'languageMode': 'hinglish',
      'inputText': 'Can I skip testing?',
      'replyText': 'Scenario ke context me evidence check karo.',
      'subtitles': <String>['Scenario ke context me evidence check karo.'],
      'voice': <String, dynamic>{
        'enabled': false,
        'fallbackToText': true,
      },
      'safety': <String, dynamic>{
        'status': 'safe',
        'blocked': false,
        'reason': 'scenario_context_ok',
      },
      'memoryBoundary': <String, dynamic>{
        'scenarioBound': true,
        'noPersistentPersonalMemory': true,
        'notice': 'Character memory is limited to the active scenario turn.',
      },
      'createdAt': '2026-06-17T00:00:00.000Z',
    });

    expect(turn.scenarioId, 'interview_voice_prototype');
    expect(turn.subtitles, isNotEmpty);
    expect(turn.safety.blocked, isFalse);
    expect(turn.memoryBoundary.noPersistentPersonalMemory, isTrue);
  });
}
