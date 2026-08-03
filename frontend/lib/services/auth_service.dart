import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  // Use 127.0.0.1 for Flutter Windows.
  // For an Android emulator, use http://10.0.2.2:8000.
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String _tokenKey = 'jwt_access_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username.trim(), 'password': password},
    );

    if (response.statusCode != 200) {
      throw AuthException(_extractError(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['access_token'] as String?;

    if (token == null || token.isEmpty) {
      throw const AuthException('The server did not return an access token.');
    }

    await _storage.write(key: _tokenKey, value: token);

    try {
      return await getCurrentUser();
    } catch (_) {
      await clearSession();
      rethrow;
    }
  }

  Future<AuthUser> getCurrentUser() async {
    final token = await getToken();

    if (token == null) {
      throw const AuthException('No active session was found.');
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 401) {
      await clearSession();

      throw const AuthException(
        'Your session has expired. Please log in again.',
      );
    }

    if (response.statusCode != 200) {
      throw AuthException(_extractError(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(body);
  }

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() {
    return clearSession();
  }

  Future<void> clearSession() {
    return _storage.delete(key: _tokenKey);
  }

  String _extractError(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map<String, dynamic>) {
        final detail = body['detail'];

        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Use the fallback message below.
    }

    return 'Request failed with status ${response.statusCode}.';
  }

  void dispose() {
    _client.close();
  }
}
