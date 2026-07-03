enum GameVisualQuality {
  performance,
  balanced,
  cinematic,
}

extension GameVisualQualityX on GameVisualQuality {
  String get storageValue => name;

  String get label {
    switch (this) {
      case GameVisualQuality.performance:
        return 'Performance';
      case GameVisualQuality.balanced:
        return 'Balanced';
      case GameVisualQuality.cinematic:
        return 'Cinematic';
    }
  }

  String get description {
    switch (this) {
      case GameVisualQuality.performance:
        return 'Reduced particles and lighter effects for low-end devices.';
      case GameVisualQuality.balanced:
        return 'Smooth motion with a moderate visual-effects budget.';
      case GameVisualQuality.cinematic:
        return 'Maximum ambient particles, glow, scanlines, and impact effects.';
    }
  }

  int get particleBudget {
    switch (this) {
      case GameVisualQuality.performance:
        return 10;
      case GameVisualQuality.balanced:
        return 22;
      case GameVisualQuality.cinematic:
        return 38;
    }
  }

  bool get usesHeavyEffects => this == GameVisualQuality.cinematic;
  bool get usesAmbientEffects => this != GameVisualQuality.performance;
}

GameVisualQuality gameVisualQualityFromStorage(String? value) {
  for (final quality in GameVisualQuality.values) {
    if (quality.storageValue == value) {
      return quality;
    }
  }
  return GameVisualQuality.balanced;
}
