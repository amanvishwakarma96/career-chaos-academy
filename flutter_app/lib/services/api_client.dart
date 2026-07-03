import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'secure_token_storage_service.dart';

class ApiClientException implements Exception {
  final String message;
  final int? statusCode;

  const ApiClientException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const Duration _timeout = Duration(seconds: 8);

  bool get isEnabled => ApiConfig.isEnabled;

  Future<List<dynamic>> getList(String path) async {
    final decoded = await _send('GET', path);
    if (decoded is List) {
      return decoded;
    }
    throw const ApiClientException('Expected a JSON list from API.');
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final decoded = await _send('GET', path);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ApiClientException('Expected a JSON object from API.');
  }

  Future<Map<String, dynamic>> postMap(
    String path,
    Map<String, dynamic> body,
  ) async {
    final decoded = await _send('POST', path, body: body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ApiClientException('Expected a JSON object from API.');
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (!ApiConfig.isEnabled) {
      throw const ApiClientException('API base URL is not configured.');
    }

    final uri = ApiConfig.uri(path);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final accessToken = await SecureTokenStorageService.instance.readAccessToken();
    final adminToken = await SecureTokenStorageService.instance.readAdminToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    if (adminToken != null && adminToken.isNotEmpty) {
      headers['X-Admin-Token'] = adminToken;
    }

    final response = method == 'POST'
        ? await http
            .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(_timeout)
        : await http.get(uri, headers: headers).timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        'API request failed for $path.',
        statusCode: response.statusCode,
      );
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    return jsonDecode(response.body) as Object?;
  }
}
