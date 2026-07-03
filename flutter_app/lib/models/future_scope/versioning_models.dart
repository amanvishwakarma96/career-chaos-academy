class ContentVersionModel {
  final String contentPackId;
  final String version;
  final String minAppVersion;
  final String checksum;
  final DateTime? publishedAt;
  final List<String> roleIds;

  const ContentVersionModel({
    required this.contentPackId,
    required this.version,
    this.minAppVersion = '1.0.0',
    this.checksum = '',
    this.publishedAt,
    this.roleIds = const <String>[],
  });

  factory ContentVersionModel.fromJson(Map<String, dynamic> json) {
    return ContentVersionModel(
      contentPackId: _readString(json['contentPackId'], fallback: 'core_roles'),
      version: _readString(json['version'], fallback: '1.0.0'),
      minAppVersion: _readString(json['minAppVersion'], fallback: '1.0.0'),
      checksum: _readString(json['checksum']),
      publishedAt: DateTime.tryParse(_readString(json['publishedAt'])),
      roleIds: _readStringList(json['roleIds']),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().where((item) => item.trim().isNotEmpty).toList(growable: false);
  }
}

class AssetVersionModel {
  final String assetPackId;
  final String version;
  final String baseUrl;
  final Map<String, String> assetVersions;

  const AssetVersionModel({
    required this.assetPackId,
    required this.version,
    this.baseUrl = '',
    this.assetVersions = const <String, String>{},
  });

  factory AssetVersionModel.fromJson(Map<String, dynamic> json) {
    return AssetVersionModel(
      assetPackId: _readString(json['assetPackId'], fallback: 'base_visuals'),
      version: _readString(json['version'], fallback: '1.0.0'),
      baseUrl: _readString(json['baseUrl']),
      assetVersions: _readStringMap(json['assetVersions']),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  static Map<String, String> _readStringMap(Object? value) {
    if (value is! Map) return const <String, String>{};
    final result = <String, String>{};
    value.forEach((key, item) {
      if (key is String && item is String) result[key] = item;
    });
    return Map<String, String>.unmodifiable(result);
  }
}
