class JsonReader {
  const JsonReader._();

  static String readString(
    Map<String, dynamic> json,
    String key, {
    required String parent,
  }) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw FormatException('$parent.$key must be a non-empty string.');
  }

  static int readInt(
    Map<String, dynamic> json,
    String key, {
    required String parent,
    int defaultValue = 0,
  }) {
    final value = json[key];
    if (value == null) {
      return defaultValue;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('$parent.$key must be a number.');
  }

  static Map<String, dynamic> readMap(
    Map<String, dynamic> json,
    String key, {
    required String parent,
  }) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw FormatException('$parent.$key must be an object.');
  }

  static List<dynamic> readList(
    Map<String, dynamic> json,
    String key, {
    required String parent,
  }) {
    final value = json[key];
    if (value is List<dynamic> && value.isNotEmpty) {
      return value;
    }
    throw FormatException('$parent.$key must be a non-empty list.');
  }
}
