import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/audit_log.dart';

class AuditApi {
  AuditApi({required this.client, String? baseUrl})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client client;
  final String baseUrl;

  Future<List<AuditLog>> getAuditLogs({
    String? action,
    String? entityType,
    String? username,
    int limit = 200,
  }) async {
    final query = <String, String>{'limit': '$limit'};

    if (action != null && action.isNotEmpty) {
      query['action'] = action;
    }

    if (entityType != null && entityType.isNotEmpty) {
      query['entity_type'] = entityType;
    }

    if (username != null && username.trim().isNotEmpty) {
      query['username'] = username.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/audit-logs/',
    ).replace(queryParameters: query);

    final response = await client.get(uri);

    _ensureSuccess(response, action: 'load audit logs');

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((entry) => AuditLog.fromJson(entry as Map<String, dynamic>))
        .toList();
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
      // Use response body as fallback.
    }

    if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    if (response.statusCode == 403) {
      throw Exception('You do not have permission to view audit logs.');
    }

    throw Exception(
      'Failed to $action: '
      '${response.statusCode} $detail',
    );
  }
}
