class ContentCacheStateModel {
  final String activeContentPackId;
  final String activeContentVersion;
  final String? lastUpdatedAt;

  const ContentCacheStateModel({
    this.activeContentPackId = 'core_roles_v23',
    this.activeContentVersion = '23.0.0',
    this.lastUpdatedAt,
  });

  static const defaults = ContentCacheStateModel();

  factory ContentCacheStateModel.fromJson(Map<String, dynamic> json) {
    return ContentCacheStateModel(
      activeContentPackId: json['activeContentPackId'] is String
          ? (json['activeContentPackId'] as String).trim()
          : 'core_roles_v23',
      activeContentVersion: json['activeContentVersion'] is String
          ? (json['activeContentVersion'] as String).trim()
          : '23.0.0',
      lastUpdatedAt: json['lastUpdatedAt'] is String
          ? (json['lastUpdatedAt'] as String).trim()
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'activeContentPackId': activeContentPackId,
        'activeContentVersion': activeContentVersion,
        'lastUpdatedAt': lastUpdatedAt,
      };
}
