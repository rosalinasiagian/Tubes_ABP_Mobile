import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    return 'http://127.0.0.1:8000/api';
  }

  static String? _token;

  // ── TOKEN MANAGEMENT ───────────────────────────────────────────────────────

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ─── Helper ───────────────────────────────────────────────────────────────

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);
    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String errorMessage = body['message'] ?? 'Error ${response.statusCode}';
      if (body['errors'] != null && body['errors'] is Map) {
        final Map errors = body['errors'];
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          errorMessage = firstError.first.toString();
        }
      }
      throw Exception(errorMessage);
    }
  }

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  /// POST /api/auth/register
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  /// POST /api/auth/login
  static Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'emailOrUsername': emailOrUsername, 'password': password}),
    );
    final data = _handleResponse(response);
    if (data['token'] != null) {
      await setToken(data['token']); // pakai await karena sekarang async
    }
    return data;
  }

  /// POST /api/auth/logout
  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    await clearToken(); // pakai await karena sekarang async
    return data;
  }

  /// GET /api/auth/verify
  static Future<bool> verifyToken() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── USER ─────────────────────────────────────────────────────────────────

  /// GET /api/user/me
  static Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/me'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// PUT /api/user/update
  static Future<Map<String, dynamic>> updateUser(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  /// POST /api/user/photo (multipart)
  static Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/user/photo'),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });
    request.files.add(await http.MultipartFile.fromPath('photo', filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  /// DELETE /api/user/photo
  static Future<Map<String, dynamic>> deletePhoto() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user/photo'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// DELETE /api/user/delete
  static Future<Map<String, dynamic>> deleteAccount(String currentPassword) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user/delete'),
      headers: _headers,
      body: jsonEncode({'currentPassword': currentPassword}),
    );
    final data = _handleResponse(response);
    await clearToken(); // pakai await karena sekarang async
    return data;
  }

  // ─── TASKS ────────────────────────────────────────────────────────────────

  /// GET /api/tasks
  static Future<List<dynamic>> getTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    if (body is List) return body;
    if (body is Map) return body['data'] ?? body['tasks'] ?? [];
    return [];
  }

  /// POST /api/tasks
  static Future<Map<String, dynamic>> createTask(Map<String, dynamic> task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _headers,
      body: jsonEncode(task),
    );
    return _handleResponse(response);
  }

  /// GET /api/tasks/{id}
  static Future<Map<String, dynamic>> getTask(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// PUT /api/tasks/{id}
  static Future<Map<String, dynamic>> updateTask(int id, Map<String, dynamic> task) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers,
      body: jsonEncode(task),
    );
    return _handleResponse(response);
  }

  /// DELETE /api/tasks/{id}
  static Future<Map<String, dynamic>> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// GET /api/tasks/stats
  static Future<Map<String, dynamic>> getTaskStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/stats'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ─── CATEGORIES ───────────────────────────────────────────────────────────

  /// GET /api/categories
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _headers,
    );
    final body = jsonDecode(response.body);
    if (body is List) return body;
    if (body is Map) return body['data'] ?? body['categories'] ?? [];
    return [];
  }

  /// POST /api/categories
  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: _headers,
      body: jsonEncode(category),
    );
    return _handleResponse(response);
  }

  /// GET /api/categories/{id}
  static Future<Map<String, dynamic>> getCategory(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  /// PUT /api/categories/{id}
  static Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> category) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
      body: jsonEncode(category),
    );
    return _handleResponse(response);
  }

  /// DELETE /api/categories/{id}
  static Future<Map<String, dynamic>> deleteCategory(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers,
    );
    return _handleResponse(response);
  }
}