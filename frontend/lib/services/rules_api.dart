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
  final String baseUrl;
  RulesApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<RulesResponse> getRules() async {
    final response = await http.get(Uri.parse('$baseUrl/rules'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load safety rules: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawRules = data['rules'] as List<dynamic>? ?? [];
    return RulesResponse(
      disclaimer: data['disclaimer']?.toString() ?? '',
      rules:
          rawRules
              .map((e) => SafetyRule.fromJson(e as Map<String, dynamic>))
              .toList(),
      configuration:
          (data['configuration'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
    );
  }
}
