import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/eval_row.dart';
import '../models/ml_metrics.dart';

class EvaluationApi {
  EvaluationApi({http.Client? client, String? baseUrl})
    : client = client ?? http.Client(),
      baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client client;
  final String baseUrl;

  Future<List<EvalRow>> getEvalLots() async {
    final response = await client.get(Uri.parse('$baseUrl/eval/lots'));

    _ensureSuccess(response, action: 'fetch evaluation lots');

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .map((entry) => EvalRow.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<MlMetrics> getMlVsBaselineMetrics() async {
    final response = await client.get(
      Uri.parse('$baseUrl/metrics/ml-vs-baseline'),
    );

    _ensureSuccess(response, action: 'fetch machine-learning metrics');

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return MlMetrics.fromJson(data);
  }

  Future<void> trainMl({double contamination = 0.10}) async {
    final url = Uri.parse('$baseUrl/ml/train?contamination=$contamination');

    final response = await client.post(url);

    _ensureSuccess(response, action: 'train the machine-learning model');
  }

  Future<List<dynamic>> getContaminationExperiment() async {
    final response = await client.get(
      Uri.parse('$baseUrl/experiments/contamination'),
    );

    _ensureSuccess(response, action: 'fetch contamination experiment results');

    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<List<dynamic>> getDatasetSizeExperiment() async {
    final response = await client.get(
      Uri.parse('$baseUrl/experiments/dataset-size'),
    );

    _ensureSuccess(response, action: 'fetch dataset-size experiment results');

    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<List<dynamic>> getRocSweep() async {
    final response = await client.get(Uri.parse('$baseUrl/metrics/roc-sweep'));

    _ensureSuccess(response, action: 'fetch ROC sweep results');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final points = data['points'];

    if (points is List<dynamic>) {
      return points;
    }

    return const [];
  }

  Future<Map<String, dynamic>> getOverviewSummary() async {
    final response = await client.get(Uri.parse('$baseUrl/summary/overview'));

    _ensureSuccess(response, action: 'fetch the overview summary');

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getConfusionMatrix() async {
    final response = await client.get(
      Uri.parse('$baseUrl/metrics/confusion-matrix'),
    );

    _ensureSuccess(response, action: 'fetch the confusion matrix');

    return jsonDecode(response.body) as Map<String, dynamic>;
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
        final value = decoded['detail'];

        if (value is String && value.isNotEmpty) {
          detail = value;
        }
      }
    } catch (_) {
      // Keep the response body as the fallback detail.
    }

    throw Exception(
      'Failed to $action: '
      '${response.statusCode} $detail',
    );
  }
}
