import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? secureStorage})
      : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _timeout = Duration(seconds: 20);
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  String? _token;

  Future<void> loadToken() async {
    _token = await _secureStorage.read(key: _tokenKey);
    if (_token == null) {
      final legacy = await SharedPreferences.getInstance();
      final legacyToken = legacy.getString('token');
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await _secureStorage.write(key: _tokenKey, value: legacyToken);
        _token = legacyToken;
      }
      await legacy.remove('token');
    }
  }

  Future<void> saveToken(String token) async {
    if (token.isEmpty || token.length > 4096) {
      throw ApiException('Invalid authentication token');
    }
    await _secureStorage.write(key: _tokenKey, value: token);
    _token = token;
  }

  Future<void> clearToken() async {
    _token = null;
    await _secureStorage.delete(key: _tokenKey);
    final legacy = await SharedPreferences.getInstance();
    await legacy.remove('token');
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);
  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);
  Future<Map<String, dynamic>> delete(String path) => _send('DELETE', path);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    if (!path.startsWith('/') || path.contains('..')) {
      throw ApiException('Invalid API path');
    }
    final uri =
        Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      if (_token?.isNotEmpty == true) 'Authorization': 'Bearer $_token',
    };

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response =
              await _httpClient.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
        case 'PATCH':
          response = await _httpClient
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(_timeout);
        case 'DELETE':
          response =
              await _httpClient.delete(uri, headers: headers).timeout(_timeout);
        default:
          throw ApiException('Unsupported request method');
      }

      dynamic decoded;
      try {
        decoded = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);
      } catch (_) {
        decoded = <String, dynamic>{};
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) await clearToken();
        final message = decoded is Map<String, dynamic>
            ? decoded['message']?.toString() ?? 'Request failed'
            : 'Request failed';
        throw ApiException(message, statusCode: response.statusCode);
      }
      return decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Secure connection failed. Please check your internet connection.');
    }
  }

  void close() => _httpClient.close();
}
