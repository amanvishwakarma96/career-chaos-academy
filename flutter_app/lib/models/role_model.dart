import '../core/json_reader.dart';

class RoleModel {
  final String id;
  final String name;
  final String description;
  final String iconKey;
  final String pluginId;
  final String contentPackId;
  final String contentVersion;
  final String contentTier;

  const RoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconKey,
    this.pluginId = '',
    this.contentPackId = 'core_roles_v23',
    this.contentVersion = '',
    this.contentTier = 'free',
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final id = JsonReader.readString(json, 'id', parent: 'role');
    return RoleModel(
      id: id,
      name: JsonReader.readString(json, 'name', parent: 'role'),
      description: JsonReader.readString(
        json,
        'description',
        parent: 'role',
      ),
      iconKey: JsonReader.readString(json, 'iconKey', parent: 'role'),
      pluginId: _readString(json['pluginId'], fallback: '${id}_core'),
      contentPackId: _readString(json['contentPackId'], fallback: 'core_roles_v23'),
      contentVersion: _readString(json['contentVersion']),
      contentTier: _readString(json['contentTier'], fallback: 'free'),
    );
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}
