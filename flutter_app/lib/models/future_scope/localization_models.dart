class LocalizedTextRefModel {
  final String key;
  final String fallback;

  const LocalizedTextRefModel({
    this.key = '',
    this.fallback = '',
  });

  factory LocalizedTextRefModel.fromJson(Object? value) {
    if (value is String) {
      return LocalizedTextRefModel(key: value);
    }
    if (value is Map<String, dynamic>) {
      return LocalizedTextRefModel(
        key: value['key'] is String ? (value['key'] as String).trim() : '',
        fallback: value['fallback'] is String ? (value['fallback'] as String).trim() : '',
      );
    }
    return const LocalizedTextRefModel();
  }
}
