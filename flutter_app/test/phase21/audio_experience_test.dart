import 'package:career_chaos_academy/core/audio_registry.dart';
import 'package:career_chaos_academy/models/dialogue_line_model.dart';
import 'package:career_chaos_academy/models/dialogue_scene_model.dart';
import 'package:career_chaos_academy/models/progress_snapshot_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 21 audio experience', () {
    test('audio registry resolves keys, direct assets, remote URLs, and unknown keys safely', () {
      expect(
        AudioRegistry.resolve('bgm_office_light', type: GameAudioType.backgroundMusic),
        'assets/game/audio/bgm_office_light.wav',
      );
      expect(
        AudioRegistry.resolve('choice_select', type: GameAudioType.soundEffect),
        'assets/game/audio/choice_select.wav',
      );
      expect(
        AudioRegistry.resolve('voice_placeholder', type: GameAudioType.voice),
        'assets/game/audio/voice_placeholder.wav',
      );
      expect(
        AudioRegistry.resolve('assets/game/audio/custom.wav'),
        'assets/game/audio/custom.wav',
      );
      expect(
        AudioRegistry.resolve('https://cdn.example.com/audio/voice.mp3'),
        'https://cdn.example.com/audio/voice.mp3',
      );
      expect(AudioRegistry.resolve('not_registered'), isNull);
      expect(
        AudioRegistry.toAudioplayersAssetPath('assets/game/audio/choice_select.wav'),
        'game/audio/choice_select.wav',
      );
    });

    test('dialogue scene parses per-scene audio config with safe defaults', () {
      final scene = DialogueSceneModel.fromJson(<String, dynamic>{
        'id': 'opening',
        'title': 'Opening',
        'backgroundImage': 'bg_office_morning',
        'audio': <String, dynamic>{
          'backgroundMusic': 'bgm_office_light',
          'soundEffect': 'notification_ping',
          'loopBackgroundMusic': true,
          'musicVolume': 0.4,
        },
        'dialogues': <Map<String, dynamic>>[
          <String, dynamic>{
            'speaker': 'Senior Dev',
            'emotion': 'serious',
            'text': 'Evidence first.',
            'audio': <String, dynamic>{
              'voiceClip': 'voice_placeholder',
              'subtitle': 'Evidence first.',
              'sfxVolume': 0.6,
            },
          },
        ],
      });

      expect(scene.audio.backgroundMusic, 'bgm_office_light');
      expect(scene.audio.soundEffect, 'notification_ping');
      expect(scene.audio.musicVolume, 0.4);
      expect(scene.dialogues.first.audio.voiceClip, 'voice_placeholder');
      expect(scene.dialogues.first.audio.subtitle, 'Evidence first.');
      expect(scene.dialogues.first.audio.sfxVolume, 0.6);
    });

    test('old dialogue JSON remains compatible without audio fields', () {
      final line = DialogueLineModel.fromJson(<String, dynamic>{
        'speaker': 'Narrator',
        'text': 'Old scene text.',
      });

      expect(line.audio.hasAudio, isFalse);
      expect(line.voiceClip, isNull);
      expect(line.subtitle, isNull);
    });

    test('progress snapshot upgrades version without breaking older progress JSON', () {
      final snapshot = ProgressSnapshotModel.fromJson(<String, dynamic>{
        'version': 7,
        'progressByRole': <String, dynamic>{},
        'totalXp': 10,
      });

      expect(snapshot.totalXp, 10);
      expect(snapshot.toJson()['version'], 8);
    });
  });
}
