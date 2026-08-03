import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/auth_user.dart';

class UsersApi {
  UsersApi({required this.client, String? baseUrl})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client client;
  final String baseUrl;

  Future<List<AuthUser>> getUsers() async {
    final response = await client.get(Uri.parse('$baseUrl/auth/users'));

    _ensureSuccess(response, action: 'load users');

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((entry) => AuthUser.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<AuthUser> createUser({
    required String username,
    required String password,
    required String role,
    String? fullName,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'full_name': fullName?.trim().isEmpty == true ? null : fullName?.trim(),
        'password': password,
        'role': role,
      }),
    );

    _ensureSuccess(response, action: 'create user');

    return AuthUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void _ensureSuccess(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String detail = response.body;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['detail'];

        if (message is String && message.isNotEmpty) {
          detail = message;
        }
      }
    } catch (_) {
      // Use the response body as fallback.
    }

    if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    if (response.statusCode == 403) {
      throw Exception('Only administrators can $action.');
    }

    throw Exception(
      'Failed to $action: '
      '${response.statusCode} $detail',
    );
  }
}
