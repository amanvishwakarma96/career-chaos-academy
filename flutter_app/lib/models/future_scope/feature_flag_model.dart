class FeatureFlagModel {
  final String key;
  final bool enabled;
  final String description;
  final String owner;
  final int rolloutPercentage;

  const FeatureFlagModel({
    required this.key,
    required this.enabled,
    this.description = '',
    this.owner = 'product',
    this.rolloutPercentage = 100,
  });

  factory FeatureFlagModel.fromJson(Map<String, dynamic> json) {
    return FeatureFlagModel(
      key: _readString(json['key']),
      enabled: json['enabled'] is bool ? json['enabled'] as bool : false,
      description: _readString(json['description']),
      owner: _readString(json['owner'], fallback: 'product'),
      rolloutPercentage: _readInt(json['rolloutPercentage'], fallback: 100).clamp(0, 100).toInt(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'enabled': enabled,
        'description': description,
        'owner': owner,
        'rolloutPercentage': rolloutPercentage,
      };

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static int _readInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
