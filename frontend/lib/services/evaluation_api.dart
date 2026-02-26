import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/eval_row.dart';
import '../models/ml_metrics.dart';

class EvaluationApi {
  final String baseUrl;
  EvaluationApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<List<EvalRow>> getEvalLots(){
    return http.get(Uri.parse('$baseUrl/eval/lots')).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch eval lots: ${res.statusCode}");
      }
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => EvalRow.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<MlMetrics> getMlVsBaselineMetrics() {
    return http.get(Uri.parse('$baseUrl/metrics/ml-vs-baseline')).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch metrics: ${res.statusCode}");
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return MlMetrics.fromJson(data);
    });
  }
}