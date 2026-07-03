class RemoteConfigModel {
  final int version;
  final DateTime? fetchedAt;
  final Map<String, dynamic> values;

  const RemoteConfigModel({
    this.version = 1,
    this.fetchedAt,
    this.values = const <String, dynamic>{},
  });

  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) {
    return RemoteConfigModel(
      version: _readInt(json['version'], fallback: 1),
      fetchedAt: DateTime.tryParse(_readString(json['fetchedAt'])),
      values: json['values'] is Map<String, dynamic>
          ? Map<String, dynamic>.unmodifiable(json['values'] as Map<String, dynamic>)
          : const <String, dynamic>{},
    );
  }

  T? value<T>(String key) {
    final item = values[key];
    return item is T ? item : null;
  }

  static String _readString(Object? value) => value is String ? value : '';
  static int _readInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
