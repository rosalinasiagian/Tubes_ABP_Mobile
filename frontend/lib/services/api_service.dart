import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _webBackendProductionOrigin =
      'https://backend-go-done-v2-production-39e7.up.railway.app';
  static const String _webBackendLocalOrigin = 'http://127.0.0.1:8000';
  static const String _configuredApiBaseUrl =
      String.fromEnvironment('API_BASE_URL');
  static const Duration requestTimeout = Duration(seconds: 20);
  static const String _tokenStorageKey = 'auth_token';
  static const String _legacyTokenStorageKey = 'token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String get apiOrigin {
    final configured = _configuredApiBaseUrl.trim();
    if (configured.isNotEmpty) return _normalizeOrigin(configured);

    if (kIsWeb) return _webBackendLocalOrigin;
    return _webBackendProductionOrigin;
  }

  static String get baseUrl => '$apiOrigin/api';

  static String? _token;

  static bool get hasToken => _token != null && _token!.isNotEmpty;

  static String _normalizeOrigin(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    return normalized;
  }

  static Future<T> _withTimeout<T>(Future<T> future) {
    return future.timeout(
      requestTimeout,
      onTimeout: () => throw Exception(
        'Koneksi ke backend timeout. Cek URL API atau koneksi internet.',
      ),
    );
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<http.Response> _get(String path) {
    return _withTimeout(http.get(_uri(path), headers: _headers));
  }

  static Future<http.Response> _post(String path, Map<String, dynamic>? body) {
    return _withTimeout(
      http.post(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  static Future<http.Response> _put(String path, Map<String, dynamic> body) {
    return _withTimeout(
      http.put(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
  }

  static Future<http.Response> _delete(String path,
      [Map<String, dynamic>? body]) {
    return _withTimeout(
      http.delete(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  static Future<void> setToken(String token) async {
    _token = token;
    await _secureStorage.write(key: _tokenStorageKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenStorageKey);
  }

  static Future<void> loadToken() async {
    _token = await _secureStorage.read(key: _tokenStorageKey);
    if (hasToken) return;

    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_legacyTokenStorageKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      _token = legacyToken;
      await _secureStorage.write(key: _tokenStorageKey, value: legacyToken);
      await prefs.remove(_legacyTokenStorageKey);
    }
  }

  static Future<void> clearToken() async {
    _token = null;
    await _secureStorage.delete(key: _tokenStorageKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenStorageKey);
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static dynamic _decodeBody(http.Response response) {
    final rawBody = response.body.trim();
    if (rawBody.isEmpty) return <String, dynamic>{};

    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return rawBody;
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = _decodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {'data': body};
    }

    var errorMessage = 'Error ${response.statusCode}';
    if (body is Map) {
      errorMessage = body['message']?.toString() ?? errorMessage;
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          errorMessage = firstError.first.toString();
        }
      }
    } else if (body is String && body.isNotEmpty) {
      errorMessage = body;
    }

    throw Exception(errorMessage);
  }

  static List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleResponse(response);
    }

    final body = _decodeBody(response);
    if (body is List) return body;
    if (body is Map) {
      return body['data'] ?? body['tasks'] ?? body['categories'] ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/register', {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
    });
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'emailOrUsername': emailOrUsername,
      'password': password,
    });
    final data = _handleResponse(response);
    if (data['token'] != null) {
      await setToken(data['token'].toString());
    }
    return data;
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _post('/auth/logout', null);
      return _handleResponse(response);
    } catch (_) {
      return {
        'success': true,
        'message': 'Logged out locally',
      };
    } finally {
      await clearToken();
    }
  }

  static Future<bool> verifyToken() async {
    final status = await verifyTokenStatus();
    return status == true;
  }

  static Future<bool?> verifyTokenStatus() async {
    try {
      final response = await _get('/auth/verify');
      if (response.statusCode == 200) return true;
      if (response.statusCode == 401 || response.statusCode == 403) {
        return false;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getUser() async {
    final response = await _get('/user/me');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUser(
      Map<String, dynamic> data) async {
    final response = await _put('/user/update', data);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    final request = http.MultipartRequest('POST', _uri('/user/photo'));
    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));

    final streamed = await _withTimeout(request.send());
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deletePhoto() async {
    final response = await _delete('/user/photo');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteAccount(
      String currentPassword) async {
    final response = await _delete('/user/delete', {
      'currentPassword': currentPassword,
    });
    final data = _handleResponse(response);
    await clearToken();
    return data;
  }

  static Future<List<dynamic>> getTasks() async {
    final response = await _get('/tasks');
    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> createTask(
      Map<String, dynamic> task) async {
    final response = await _post('/tasks', task);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTask(int id) async {
    final response = await _get('/tasks/$id');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateTask(
    int id,
    Map<String, dynamic> task,
  ) async {
    final response = await _put('/tasks/$id', task);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteTask(int id) async {
    final response = await _delete('/tasks/$id');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTaskStats() async {
    final response = await _get('/tasks/stats');
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await _get('/categories');
    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> createCategory(
    Map<String, dynamic> category,
  ) async {
    final response = await _post('/categories', category);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCategory(int id) async {
    final response = await _get('/categories/$id');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCategory(
    int id,
    Map<String, dynamic> category,
  ) async {
    final response = await _put('/categories/$id', category);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteCategory(int id) async {
    final response = await _delete('/categories/$id');
    return _handleResponse(response);
  }
}
