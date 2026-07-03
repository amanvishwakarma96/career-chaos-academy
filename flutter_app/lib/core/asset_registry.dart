enum GameAssetType {
  background,
  character,
  prop,
  badge,
  lottie,
  rive,
  audio,
}

class AssetRegistry {
  const AssetRegistry._();

  static const String gameAssetRoot = 'assets/game';
  static const String baseAssetPackId = 'base_visuals_v23';
  static const String baseAssetVersion = '23.0.0';
  static const String missingImagePlaceholder =
      '$gameAssetRoot/props/missing_asset_placeholder.png';

  static const Map<String, String> backgrounds = <String, String>{
    'bg_office_morning': '$gameAssetRoot/backgrounds/office_morning.png',
    'bg_production_war_room':
        '$gameAssetRoot/backgrounds/production_war_room.png',
    'bg_clinic_waiting_room':
        '$gameAssetRoot/backgrounds/clinic_waiting_room.png',
    'bg_doctor_consult_room':
        '$gameAssetRoot/backgrounds/doctor_consult_room.png',
  };

  static const Map<String, String> characters = <String, String>{
    'char_developer_neutral': '$gameAssetRoot/characters/developer_neutral.png',
    'char_developer_worried': '$gameAssetRoot/characters/developer_worried.png',
    'char_developer_focused': '$gameAssetRoot/characters/developer_focused.png',
    'char_senior_serious': '$gameAssetRoot/characters/senior_serious.png',
    'char_senior_calm': '$gameAssetRoot/characters/senior_calm.png',
    'char_manager_panic': '$gameAssetRoot/characters/manager_panic.png',
    'char_manager_angry': '$gameAssetRoot/characters/manager_angry.png',
    'char_doctor_calm': '$gameAssetRoot/characters/doctor_calm.png',
    'char_doctor_focused': '$gameAssetRoot/characters/doctor_focused.png',
    'char_patient_worried': '$gameAssetRoot/characters/patient_worried.png',
    'char_patient_relieved': '$gameAssetRoot/characters/patient_relieved.png',
    'char_nurse_serious': '$gameAssetRoot/characters/nurse_serious.png',
    'char_nurse_calm': '$gameAssetRoot/characters/nurse_calm.png',
  };

  static const Map<String, String> props = <String, String>{
    'prop_missing_asset': missingImagePlaceholder,
  };

  static const Map<String, String> badges = <String, String>{
    'badge_placeholder': '$gameAssetRoot/badges/badge_placeholder.png',
  };

  static const Map<String, String> lottie = <String, String>{};
  static const Map<String, String> rive = <String, String>{};
  static const Map<String, String> audio = <String, String>{};

  static const Map<String, String> assetVersions = <String, String>{
    'bg_office_morning': baseAssetVersion,
    'bg_production_war_room': baseAssetVersion,
    'bg_clinic_waiting_room': baseAssetVersion,
    'bg_doctor_consult_room': baseAssetVersion,
    'char_developer_worried': baseAssetVersion,
    'char_senior_serious': baseAssetVersion,
    'char_doctor_calm': baseAssetVersion,
  };

  static const Map<String, String> _legacyAliases = <String, String>{
    'assets/cinematic/backgrounds/office_morning.png':
        '$gameAssetRoot/backgrounds/office_morning.png',
    'assets/cinematic/backgrounds/production_war_room.png':
        '$gameAssetRoot/backgrounds/production_war_room.png',
    'assets/cinematic/backgrounds/clinic_waiting_room.png':
        '$gameAssetRoot/backgrounds/clinic_waiting_room.png',
    'assets/cinematic/backgrounds/doctor_consult_room.png':
        '$gameAssetRoot/backgrounds/doctor_consult_room.png',
    'assets/cinematic/characters/developer_worried.png':
        '$gameAssetRoot/characters/developer_worried.png',
    'assets/cinematic/characters/senior_serious.png':
        '$gameAssetRoot/characters/senior_serious.png',
    'assets/cinematic/characters/manager_panic.png':
        '$gameAssetRoot/characters/manager_panic.png',
    'assets/cinematic/characters/doctor_calm.png':
        '$gameAssetRoot/characters/doctor_calm.png',
    'assets/cinematic/characters/patient_worried.png':
        '$gameAssetRoot/characters/patient_worried.png',
    'assets/cinematic/characters/nurse_serious.png':
        '$gameAssetRoot/characters/nurse_serious.png',
  };

  static String? resolve(
    String? reference, {
    GameAssetType? type,
    bool allowUnknownAssetPath = true,
  }) {
    final value = reference?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (isRemoteUrl(value)) {
      return value;
    }

    final alias = _legacyAliases[value];
    if (alias != null) {
      return alias;
    }

    final scoped = _mapForType(type)[value];
    if (scoped != null) {
      return scoped;
    }

    for (final map in <Map<String, String>>[
      backgrounds,
      characters,
      props,
      badges,
      lottie,
      rive,
      audio,
    ]) {
      final resolved = map[value];
      if (resolved != null) {
        return resolved;
      }
    }

    if (allowUnknownAssetPath && value.startsWith('assets/')) {
      return value;
    }

    return null;
  }

  static bool isRemoteUrl(String reference) {
    final uri = Uri.tryParse(reference);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static bool isRegisteredKey(String reference) {
    return resolve(reference, allowUnknownAssetPath: false) != null;
  }

  static String versionFor(String reference) {
    return assetVersions[reference] ?? baseAssetVersion;
  }

  static Map<String, String> _mapForType(GameAssetType? type) {
    switch (type) {
      case GameAssetType.background:
        return backgrounds;
      case GameAssetType.character:
        return characters;
      case GameAssetType.prop:
        return props;
      case GameAssetType.badge:
        return badges;
      case GameAssetType.lottie:
        return lottie;
      case GameAssetType.rive:
        return rive;
      case GameAssetType.audio:
        return audio;
      case null:
        return const <String, String>{};
    }
  }
}
