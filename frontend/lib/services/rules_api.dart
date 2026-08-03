import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/safety_rule.dart';

class RulesResponse {
  final String disclaimer;
  final List<SafetyRule> rules;
  final Map<String, dynamic> configuration;

  const RulesResponse({
    required this.disclaimer,
    required this.rules,
    required this.configuration,
  });
}

class RulesApi {
  RulesApi({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client client;
  final String baseUrl;

  Future<RulesResponse> getRules() async {
    final response = await client.get(Uri.parse('$baseUrl/rules'));

    _ensureSuccess(response, action: 'load safety rules');

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final rawRules = data['rules'] as List<dynamic>? ?? <dynamic>[];

    final rawConfiguration = data['configuration'];

    return RulesResponse(
      disclaimer: data['disclaimer']?.toString() ?? '',
      rules:
          rawRules
              .map(
                (entry) => SafetyRule.fromJson(entry as Map<String, dynamic>),
              )
              .toList(),
      configuration:
          rawConfiguration is Map<String, dynamic>
              ? rawConfiguration
              : <String, dynamic>{},
    );
  }

  void _ensureSuccess(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    if (response.statusCode == 403) {
      throw Exception('You do not have permission to $action.');
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
      // Keep the original response body.
    }

    throw Exception(
      'Failed to $action: '
      '${response.statusCode} $detail',
    );
  }
}
