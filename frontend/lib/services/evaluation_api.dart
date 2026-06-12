import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/eval_row.dart';
import '../models/ml_metrics.dart';

class EvaluationApi {
  final String baseUrl;
  EvaluationApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<List<EvalRow>> getEvalLots() {
    return http.get(Uri.parse('$baseUrl/eval/lots')).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch eval lots: ${res.statusCode}");
      }
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((e) => EvalRow.fromJson(e as Map<String, dynamic>))
          .toList();
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

  Future<void> trainMl({double contamination = 0.10}) {
    final url = Uri.parse('$baseUrl/ml/train?contamination=$contamination');
    return http.post(url).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to train ML: ${res.statusCode} ${res.body}");
      }
    });
  }

  Future<List<dynamic>> getContaminationExperiment() {
    return http.get(Uri.parse('$baseUrl/experiments/contamination')).then((
      res,
    ) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch contamination experiment");
      }
      return jsonDecode(res.body) as List<dynamic>;
    });
  }

  Future<List<dynamic>> getDatasetSizeExperiment() {
    return http.get(Uri.parse('$baseUrl/experiments/dataset-size')).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch dataset size experiment");
      }
      return jsonDecode(res.body) as List<dynamic>;
    });
  }

  Future<List<dynamic>> getRocSweep() {
    return http.get(Uri.parse('$baseUrl/metrics/roc-sweep')).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch ROC sweep");
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      return data["points"] ?? [];
    });
  }

  Future<Map<String, dynamic>> getOverviewSummary() {
    return http.get(Uri.parse('$baseUrl/summary/overview')).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch overview summary");
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    });
  }

  Future<Map<String, dynamic>> getConfusionMatrix() {
    return http.get(Uri.parse('$baseUrl/metrics/confusion-matrix')).then((res) {
      if (res.statusCode != 200) {
        throw Exception("Failed to fetch confusion matrix");
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    });
  }
}
