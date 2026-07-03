import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/audio_registry.dart';
import '../models/audio_config_model.dart';
import '../models/dialogue_line_model.dart';
import '../models/dialogue_scene_model.dart';
import '../models/scenario_model.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  static const String _mutedKey = 'career_chaos_audio_muted';
  static const String _musicVolumeKey = 'career_chaos_music_volume';
  static const String _sfxVolumeKey = 'career_chaos_sfx_volume';
  static const String _voiceVolumeKey = 'career_chaos_voice_volume';

  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);
  final ValueNotifier<double> musicVolume = ValueNotifier<double>(0.45);
  final ValueNotifier<double> sfxVolume = ValueNotifier<double>(0.70);
  final ValueNotifier<double> voiceVolume = ValueNotifier<double>(0.75);

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'career_chaos_bgm');
  final AudioPlayer _sfxPlayer = AudioPlayer(playerId: 'career_chaos_sfx');
  final AudioPlayer _voicePlayer = AudioPlayer(playerId: 'career_chaos_voice');

  String? _currentMusicReference;

  bool get isMuted => muted.value;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    muted.value = preferences.getBool(_mutedKey) ?? false;
    musicVolume.value = preferences.getDouble(_musicVolumeKey) ?? 0.45;
    sfxVolume.value = preferences.getDouble(_sfxVolumeKey) ?? 0.70;
    voiceVolume.value = preferences.getDouble(_voiceVolumeKey) ?? 0.75;
    await _musicPlayer.setVolume(isMuted ? 0 : musicVolume.value);
    await _sfxPlayer.setVolume(isMuted ? 0 : sfxVolume.value);
    await _voicePlayer.setVolume(isMuted ? 0 : voiceVolume.value);
  }

  Future<void> setMuted(bool value) async {
    muted.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_mutedKey, value);
    await _musicPlayer.setVolume(value ? 0 : musicVolume.value);
    await _sfxPlayer.setVolume(value ? 0 : sfxVolume.value);
    await _voicePlayer.setVolume(value ? 0 : voiceVolume.value);
    if (value) {
      await stopAll();
    }
  }

  Future<void> setMusicVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    musicVolume.value = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_musicVolumeKey, next);
    await _musicPlayer.setVolume(isMuted ? 0 : next);
  }

  Future<void> setSfxVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    sfxVolume.value = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_sfxVolumeKey, next);
    await _sfxPlayer.setVolume(isMuted ? 0 : next);
  }

  Future<void> setVoiceVolume(double value) async {
    final next = value.clamp(0.0, 1.0).toDouble();
    voiceVolume.value = next;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_voiceVolumeKey, next);
    await _voicePlayer.setVolume(isMuted ? 0 : next);
  }

  Future<void> preloadScenarioAudio(ScenarioModel scenario) async {
    if (isMuted) {
      return;
    }
    final references = <_AudioCue>{};
    for (final scene in scenario.scenes) {
      _addCue(references, scene.audio.backgroundMusic, GameAudioType.backgroundMusic);
      _addCue(references, scene.audio.soundEffect ?? scene.soundEffect, GameAudioType.soundEffect);
      _addCue(references, scene.audio.voiceClip, GameAudioType.voice);
      for (final line in scene.dialogues) {
        _addCue(references, line.audio.soundEffect ?? line.soundEffect, GameAudioType.soundEffect);
        _addCue(references, line.audio.voiceClip ?? line.voiceClip, GameAudioType.voice);
      }
    }
    for (final cue in references) {
      await _safePreload(cue.reference, cue.type);
    }
  }

  Future<void> playSceneAudio(DialogueSceneModel scene) async {
    final audio = scene.audio;
    if (audio.stopBackgroundMusic) {
      await stopBackgroundMusic();
    }
    if (audio.backgroundMusic != null) {
      await playBackgroundMusic(
        audio.backgroundMusic!,
        loop: audio.loopBackgroundMusic,
        volumeOverride: audio.musicVolume,
      );
    }
    await playSoundEffect(audio.soundEffect ?? scene.soundEffect, volumeOverride: audio.sfxVolume);
    await playVoice(audio.voiceClip, volumeOverride: audio.voiceVolume);
  }

  Future<void> playDialogueAudio(DialogueLineModel line) async {
    await playSoundEffect(line.audio.soundEffect ?? line.soundEffect, volumeOverride: line.audio.sfxVolume);
    await playVoice(line.audio.voiceClip ?? line.voiceClip, volumeOverride: line.audio.voiceVolume);
  }

  Future<void> playBackgroundMusic(
    String reference, {
    bool loop = true,
    double? volumeOverride,
  }) async {
    if (isMuted) {
      return;
    }
    final resolved = AudioRegistry.resolve(
      reference,
      type: GameAudioType.backgroundMusic,
    );
    if (resolved == null) {
      return;
    }
    if (_currentMusicReference == resolved) {
      return;
    }
    _currentMusicReference = resolved;
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await _musicPlayer.play(
        _sourceFor(resolved),
        volume: isMuted ? 0 : (volumeOverride ?? musicVolume.value),
      );
    } catch (_) {
      _currentMusicReference = null;
    }
  }

  Future<void> playSoundEffect(
    String? reference, {
    double? volumeOverride,
  }) async {
    if (isMuted) {
      return;
    }
    final resolved = AudioRegistry.resolve(reference, type: GameAudioType.soundEffect);
    if (resolved == null) {
      return;
    }
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(
        _sourceFor(resolved),
        volume: isMuted ? 0 : (volumeOverride ?? sfxVolume.value),
      );
    } catch (_) {
      // Audio must never break gameplay.
    }
  }

  Future<void> playVoice(
    String? reference, {
    double? volumeOverride,
  }) async {
    if (isMuted) {
      return;
    }
    final resolved = AudioRegistry.resolve(reference, type: GameAudioType.voice);
    if (resolved == null) {
      return;
    }
    try {
      await _voicePlayer.stop();
      await _voicePlayer.play(
        _sourceFor(resolved),
        volume: isMuted ? 0 : (volumeOverride ?? voiceVolume.value),
      );
    } catch (_) {
      // Voice clips are optional and future-ready.
    }
  }

  Future<void> playChoiceSelect() => playSoundEffect('choice_select');

  Future<void> playResultSfx({required bool isSuccess}) {
    return playSoundEffect(isSuccess ? 'success_stinger' : 'failure_stinger');
  }

  Future<void> playBadgeUnlock() => playSoundEffect('badge_unlock');

  Future<void> playFunnyFailure() => playSoundEffect('comedy_bonk');

  Future<void> stopBackgroundMusic() async {
    _currentMusicReference = null;
    await _musicPlayer.stop();
  }

  Future<void> stopSceneAudio() async {
    await _voicePlayer.stop();
    await stopBackgroundMusic();
  }

  Future<void> stopAll() async {
    _currentMusicReference = null;
    await Future.wait(<Future<void>>[
      _musicPlayer.stop(),
      _sfxPlayer.stop(),
      _voicePlayer.stop(),
    ]);
  }

  Future<void> dispose() async {
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
    await _voicePlayer.dispose();
  }

  Future<void> _safePreload(String reference, GameAudioType type) async {
    final resolved = AudioRegistry.resolve(reference, type: type);
    if (resolved == null) {
      return;
    }
    try {
      final player = AudioPlayer(playerId: 'preload_${reference.hashCode}');
      await player.setSource(_sourceFor(resolved));
      await player.dispose();
    } catch (_) {
      // Missing/invalid audio must not block scene loading.
    }
  }

  Source _sourceFor(String resolved) {
    if (AudioRegistry.isRemoteUrl(resolved)) {
      return UrlSource(resolved);
    }
    return AssetSource(AudioRegistry.toAudioplayersAssetPath(resolved));
  }

  void _addCue(Set<_AudioCue> cues, String? reference, GameAudioType type) {
    final value = reference?.trim();
    if (value == null || value.isEmpty) {
      return;
    }
    cues.add(_AudioCue(value, type));
  }
}

class _AudioCue {
  final String reference;
  final GameAudioType type;

  const _AudioCue(this.reference, this.type);

  @override
  bool operator ==(Object other) {
    return other is _AudioCue &&
        other.reference == reference &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(reference, type);
}
