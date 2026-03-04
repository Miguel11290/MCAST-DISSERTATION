import 'package:flutter/material.dart';
import '../services/evaluation_api.dart';
import '../models/ml_metrics.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  final api = EvaluationApi();

  String? error;
  bool loading = true;
  MlMetrics? m;

  bool needsTraining = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      loading = true;
      error = null;
      needsTraining = false;
    });

    api.getMlVsBaselineMetrics().then((metrics) {
      setState(() {
        m = metrics;
        loading = false;
      });
    }).catchError((e) {
      final msg = e.toString();

      // If backend returns 400, you usually need to train ML first.
      // The EvaluationApi throws exceptions containing the status/body.
      final is400 = msg.contains(" 400") || msg.contains("statusCode: 400") || msg.contains("400");

      setState(() {
        m = null;
        loading = false;
        needsTraining = is400;
        error = is400
            ? "Metrics not available yet. Train the ML model first, then refresh."
            : msg;
      });
    });
  }

  void _trainMl() {
    setState(() {
      loading = true;
      error = null;
    });

    api.trainMl(contamination: 0.10).then((_) {
      _load();
    }).catchError((e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // top actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _trainMl,
                icon: const Icon(Icons.model_training),
                label: const Text("Train ML"),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(error!),
            ),

          const SizedBox(height: 12),

          if (m == null)
            Expanded(
              child: Center(
                child: Text(
                  needsTraining
                      ? "Train the model, then refresh to see metrics."
                      : "No metrics available.",
                ),
              ),
            )
          else
            _metricsBody(m!),
        ],
      ),
    );
  }

  Widget _metricsBody(MlMetrics m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Precision: ${m.precision.toStringAsFixed(3)}"),
        Text("Recall: ${m.recall.toStringAsFixed(3)}"),
        Text("F1-score: ${m.f1.toStringAsFixed(3)}"),
        Text("Accuracy: ${m.accuracy.toStringAsFixed(3)}"),
        const SizedBox(height: 12),
        Text("TP: ${m.tp} | FP: ${m.fp} | TN: ${m.tn} | FN: ${m.fn}"),
      ],
    );
  }
}