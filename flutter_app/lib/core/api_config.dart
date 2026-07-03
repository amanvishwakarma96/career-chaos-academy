class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'CAREER_CHAOS_API_BASE_URL',
    defaultValue: '',
  );

  static bool get isEnabled => baseUrl.trim().isNotEmpty;

  static Uri uri(String path) {
    final cleanedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanedBaseUrl$cleanedPath');
  }
}
