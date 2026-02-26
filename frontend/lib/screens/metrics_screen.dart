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

  @override
  void initState() {
    super.initState();

    api
        .getMlVsBaselineMetrics()
        .then((metrics) {
          setState(() {
            m = metrics;
            loading = false;
          });
        })
        .catchError((e) {
          setState(() {
            error = e.toString();
            loading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }
    if (m == null) {
      return const Center(child: Text("No metrics available"));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Precision: ${m!.precision.toStringAsFixed(3)}"),
          Text("Recall: ${m!.recall.toStringAsFixed(3)}"),
          Text("F1-score: ${m!.f1.toStringAsFixed(3)}"),
          Text("Accuracy: ${m!.accuracy.toStringAsFixed(3)}"),
          const SizedBox(height: 12),
          Text("TP: ${m!.tp} | FP: ${m!.fp} | TN: ${m!.tn} | FN: ${m!.fn}"),
        ],
      ),
    );
  }
}
