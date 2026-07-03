import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Production token storage wrapper.
///
/// Uses the platform keychain/keystore through flutter_secure_storage. The in-memory
/// fallback is only for unit tests or unsupported development environments and must
/// not be used as a production persistence layer.
class SecureTokenStorageService {
  SecureTokenStorageService._();

  static final SecureTokenStorageService instance = SecureTokenStorageService._();

  static const String _accessTokenKey = 'career_chaos_access_token';
  static const String _refreshTokenKey = 'career_chaos_refresh_token';
  static const String _adminTokenKey = 'career_chaos_admin_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    wOptions: WindowsOptions(),
    lOptions: LinuxOptions(),
    webOptions: WebOptions(
      dbName: 'career_chaos_secure_storage',
      publicKey: 'career_chaos_public_key',
    ),
  );

  final Map<String, String> _memoryFallback = <String, String>{};

  Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _write(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _write(_refreshTokenKey, refreshToken);
    }
  }

  Future<String?> readAccessToken() => _read(_accessTokenKey);

  Future<String?> readRefreshToken() => _read(_refreshTokenKey);

  Future<void> saveAdminToken(String token) => _write(_adminTokenKey, token);

  Future<String?> readAdminToken() => _read(_adminTokenKey);

  Future<void> clearAuthTokens() async {
    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
    await _delete(_adminTokenKey);
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      _memoryFallback[key] = value;
      if (kDebugMode) {
        debugPrint('Secure storage write fallback used for $key: $error');
      }
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key) ?? _memoryFallback[key];
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Secure storage read fallback used for $key: $error');
      }
      return _memoryFallback[key];
    }
  }

  Future<void> _delete(String key) async {
    _memoryFallback.remove(key);
    try {
      await _storage.delete(key: key);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Secure storage delete fallback used for $key: $error');
      }
    }
  }
}
