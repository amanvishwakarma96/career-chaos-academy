enum GameAudioType { backgroundMusic, soundEffect, voice }

class AudioRegistry {
  const AudioRegistry._();

  static const String audioAssetRoot = 'assets/game/audio/';

  static const Map<String, String> _backgroundMusic = <String, String>{
    'bgm_office_light': '${audioAssetRoot}bgm_office_light.wav',
    'bgm_clinic_calm': '${audioAssetRoot}bgm_clinic_calm.wav',
    'bgm_cinematic_tension': '${audioAssetRoot}bgm_cinematic_tension.wav',
  };

  static const Map<String, String> _soundEffects = <String, String>{
    'notification_ping': '${audioAssetRoot}notification_ping.wav',
    'choice_select': '${audioAssetRoot}choice_select.wav',
    'success_stinger': '${audioAssetRoot}success_stinger.wav',
    'failure_stinger': '${audioAssetRoot}failure_stinger.wav',
    'badge_unlock': '${audioAssetRoot}badge_unlock.wav',
    'comedy_bonk': '${audioAssetRoot}comedy_bonk.wav',
  };

  static const Map<String, String> _voice = <String, String>{
    'voice_placeholder': '${audioAssetRoot}voice_placeholder.wav',
  };

  static Map<String, String> get manifest => <String, String>{
        ..._backgroundMusic,
        ..._soundEffects,
        ..._voice,
      };

  static String? resolve(
    String? reference, {
    GameAudioType type = GameAudioType.soundEffect,
  }) {
    final value = reference?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (isRemoteUrl(value) || value.startsWith('assets/')) {
      return value;
    }
    return switch (type) {
      GameAudioType.backgroundMusic => _backgroundMusic[value] ?? _soundEffects[value] ?? _voice[value],
      GameAudioType.soundEffect => _soundEffects[value] ?? _backgroundMusic[value] ?? _voice[value],
      GameAudioType.voice => _voice[value] ?? _soundEffects[value] ?? _backgroundMusic[value],
    };
  }

  static bool isRemoteUrl(String reference) {
    final lower = reference.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  static String toAudioplayersAssetPath(String resolvedAssetPath) {
    return resolvedAssetPath.startsWith('assets/')
        ? resolvedAssetPath.substring('assets/'.length)
        : resolvedAssetPath;
  }
}
