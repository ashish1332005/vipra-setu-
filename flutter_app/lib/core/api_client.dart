import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) {
    return _send('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) {
    return _send('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send('DELETE', path);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer $_token',
    };

    late final http.Response response;
    try {
      if (method == 'GET') {
        response = await _httpClient.get(uri, headers: headers);
      } else if (method == 'POST') {
        response = await _httpClient.post(uri,
            headers: headers, body: jsonEncode(body ?? {}));
      } else if (method == 'PUT') {
        response = await _httpClient.put(uri,
            headers: headers, body: jsonEncode(body ?? {}));
      } else if (method == 'PATCH') {
        response = await _httpClient.patch(uri,
            headers: headers, body: jsonEncode(body ?? {}));
      } else if (method == 'DELETE') {
        response = await _httpClient.delete(uri, headers: headers);
      } else {
        throw ApiException('Unsupported method $method');
      }
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(_networkErrorMessage(error, uri));
    }

    dynamic decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      decoded = <String, dynamic>{'message': response.body};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString() ?? 'Request failed'
          : 'Request failed';
      throw ApiException(message);
    }
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};
  }
}

String _networkErrorMessage(Object error, Uri uri) {
  final message = error.toString();
  if (message.contains('Failed to fetch') ||
      message.contains('Connection refused') ||
      message.contains('XMLHttpRequest')) {
    return 'Backend server connect nahi ho raha (${uri.host}:${uri.port}). Server start karein aur MONGO_URI check karein.';
  }
  if (message.contains('Failed host lookup')) {
    return 'Backend URL resolve nahi ho raha. API_BASE_URL check karein.';
  }
  return 'Network request failed. Backend server aur internet connection check karein.';
}
