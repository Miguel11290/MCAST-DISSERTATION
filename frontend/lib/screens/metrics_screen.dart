import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/ml_metrics.dart';
import '../services/evaluation_api.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({
    required this.client,
    required this.currentUser,
    super.key,
  });

  final http.Client client;
  final AuthUser currentUser;

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  late final EvaluationApi api;

  String? error;
  bool loading = true;
  MlMetrics? metrics;
  bool needsTraining = false;

  @override
  void initState() {
    super.initState();

    api = EvaluationApi(client: widget.client);

    _load();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }

    setState(() {
      loading = true;
      error = null;
      needsTraining = false;
    });

    try {
      final result = await api.getMlVsBaselineMetrics();

      if (!mounted) {
        return;
      }

      setState(() {
        metrics = result;
        loading = false;
      });
    } catch (exception) {
      final message = exception.toString();

      final isTrainingRequired =
          message.contains('400') || message.toLowerCase().contains('train');

      if (!mounted) {
        return;
      }

      setState(() {
        metrics = null;
        loading = false;
        needsTraining = isTrainingRequired;
        error =
            isTrainingRequired
                ? 'Metrics are not available yet because the machine-learning '
                    'model has not been trained.'
                : message;
      });
    }
  }

  Future<void> _trainMl() async {
    if (!widget.currentUser.canRunExperiments) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await api.trainMl(contamination: 0.10);

      await _load();
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        error = exception.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              if (widget.currentUser.canRunExperiments) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _trainMl,
                  icon: const Icon(Icons.model_training),
                  label: const Text('Retrain ML'),
                ),
              ],
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(error!),
            ),
          ],
          const SizedBox(height: 12),
          if (metrics == null)
            Expanded(
              child: Center(
                child: Text(
                  needsTraining
                      ? widget.currentUser.canRunExperiments
                          ? 'The model has not been trained yet. '
                              'Select Retrain ML to initialise it.'
                          : 'The model has not been trained yet. '
                              'Ask an administrator or safety officer to train it.'
                      : 'No metrics are available.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Expanded(child: ListView(children: [_metricsBody(metrics!)])),
        ],
      ),
    );
  }

  Widget _metricsBody(MlMetrics value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Machine Learning Performance',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard(
              'Precision',
              value.precision,
              Icons.check_circle_outline,
            ),
            _metricCard('Recall', value.recall, Icons.search),
            _metricCard('F1-score', value.f1, Icons.balance),
            _metricCard('Accuracy', value.accuracy, Icons.analytics_outlined),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Confusion Matrix Values',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _countCard('True Positives', value.tp),
            _countCard('False Positives', value.fp),
            _countCard('True Negatives', value.tn),
            _countCard('False Negatives', value.fn),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Text(
            'Precision indicates how often anomaly predictions are correct, '
            'while recall indicates how many rule-defined unsafe records are '
            'detected by the model. In a safety-critical environment, false '
            'negatives require particular attention because they represent '
            'unsafe conditions that were not detected by machine learning.',
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, double value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(3),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _countCard(String title, int value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
