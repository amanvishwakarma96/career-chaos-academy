class RolePluginModel {
  final String pluginId;
  final String roleId;
  final String displayName;
  final String routeKey;
  final String contentPackId;
  final bool enabled;
  final List<String> requiredFeatureFlags;

  const RolePluginModel({
    required this.pluginId,
    required this.roleId,
    required this.displayName,
    this.routeKey = 'default_role_flow',
    this.contentPackId = 'core_roles',
    this.enabled = true,
    this.requiredFeatureFlags = const <String>[],
  });

  factory RolePluginModel.fromJson(Map<String, dynamic> json) {
    return RolePluginModel(
      pluginId: _readString(json['pluginId']),
      roleId: _readString(json['roleId']),
      displayName: _readString(json['displayName']),
      routeKey: _readString(json['routeKey'], fallback: 'default_role_flow'),
      contentPackId: _readString(json['contentPackId'], fallback: 'core_roles'),
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      requiredFeatureFlags: _readStringList(json['requiredFeatureFlags']),
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
