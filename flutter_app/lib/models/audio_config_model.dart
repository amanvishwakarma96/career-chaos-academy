class AudioConfigModel {
  final String? backgroundMusic;
  final String? soundEffect;
  final String? voiceClip;
  final String? subtitle;
  final bool loopBackgroundMusic;
  final bool stopBackgroundMusic;
  final double? musicVolume;
  final double? sfxVolume;
  final double? voiceVolume;

  const AudioConfigModel({
    this.backgroundMusic,
    this.soundEffect,
    this.voiceClip,
    this.subtitle,
    this.loopBackgroundMusic = true,
    this.stopBackgroundMusic = false,
    this.musicVolume,
    this.sfxVolume,
    this.voiceVolume,
  });

  static const empty = AudioConfigModel();

  bool get hasAudio =>
      backgroundMusic != null ||
      soundEffect != null ||
      voiceClip != null ||
      stopBackgroundMusic;

  factory AudioConfigModel.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return AudioConfigModel.empty;
    }
    return AudioConfigModel(
      backgroundMusic: _readNullableString(
        value['backgroundMusic'] ?? value['bgm'] ?? value['music'],
      ),
      soundEffect: _readNullableString(
        value['soundEffect'] ?? value['sfx'],
      ),
      voiceClip: _readNullableString(
        value['voiceClip'] ?? value['voice'] ?? value['voiceOver'],
      ),
      subtitle: _readNullableString(value['subtitle'] ?? value['caption']),
      loopBackgroundMusic: _readBool(value['loopBackgroundMusic'] ?? value['loopBgm'], fallback: true),
      stopBackgroundMusic: _readBool(value['stopBackgroundMusic'] ?? value['stopBgm']),
      musicVolume: _readVolume(value['musicVolume'] ?? value['bgmVolume']),
      sfxVolume: _readVolume(value['sfxVolume']),
      voiceVolume: _readVolume(value['voiceVolume']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (backgroundMusic != null) 'backgroundMusic': backgroundMusic,
      if (soundEffect != null) 'soundEffect': soundEffect,
      if (voiceClip != null) 'voiceClip': voiceClip,
      if (subtitle != null) 'subtitle': subtitle,
      'loopBackgroundMusic': loopBackgroundMusic,
      'stopBackgroundMusic': stopBackgroundMusic,
      if (musicVolume != null) 'musicVolume': musicVolume,
      if (sfxVolume != null) 'sfxVolume': sfxVolume,
      if (voiceVolume != null) 'voiceVolume': voiceVolume,
    };
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static bool _readBool(Object? value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    return fallback;
  }

  static double? _readVolume(Object? value) {
    if (value is num) {
      return value.toDouble().clamp(0.0, 1.0).toDouble();
    }
    return null;
  }
}
