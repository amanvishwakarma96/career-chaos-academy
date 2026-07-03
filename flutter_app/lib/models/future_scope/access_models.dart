enum ContentAccessTier { free, premium, creatorOnly }

class ContentAccessModel {
  final ContentAccessTier tier;
  final bool isLockedPlaceholder;
  final String unlockHint;

  const ContentAccessModel({
    this.tier = ContentAccessTier.free,
    this.isLockedPlaceholder = false,
    this.unlockHint = '',
  });

  static const free = ContentAccessModel();

  factory ContentAccessModel.fromJson(Map<String, dynamic> json) {
    return ContentAccessModel(
      tier: _readTier(json['tier'] ?? json['contentTier']),
      isLockedPlaceholder: json['isLockedPlaceholder'] is bool
          ? json['isLockedPlaceholder'] as bool
          : false,
      unlockHint: json['unlockHint'] is String ? (json['unlockHint'] as String).trim() : '',
    );
  }

  static ContentAccessTier _readTier(Object? value) {
    final raw = value is String ? value.trim().toLowerCase() : '';
    switch (raw) {
      case 'premium':
        return ContentAccessTier.premium;
      case 'creator_only':
      case 'creatoronly':
        return ContentAccessTier.creatorOnly;
      default:
        return ContentAccessTier.free;
    }
  }
}
