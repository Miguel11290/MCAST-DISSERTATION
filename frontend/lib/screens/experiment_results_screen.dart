import 'package:flutter/material.dart';
import '../services/evaluation_api.dart';
import '../models/ml_metrics.dart';

class ExperimentResultsScreen extends StatefulWidget {
  const ExperimentResultsScreen({super.key});

  @override
  State<ExperimentResultsScreen> createState() =>
      _ExperimentResultsScreenState();
}

class _ExperimentResultsScreenState extends State<ExperimentResultsScreen> {
  final api = EvaluationApi();

  bool loading = true;
  String? error;

  MlMetrics? metrics;
  List<dynamic> rocPoints = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      loading = true;
      error = null;
    });

    api
        .getMlVsBaselineMetrics()
        .then((m) {
          api
              .getRocSweep()
              .then((roc) {
                setState(() {
                  metrics = m;
                  rocPoints = roc;
                  loading = false;
                });
              })
              .catchError((e) {
                setState(() {
                  metrics = m;
                  rocPoints = [];
                  error = e.toString();
                  loading = false;
                });
              });
        })
        .catchError((e) {
          setState(() {
            metrics = null;
            rocPoints = [];
            error = e.toString();
            loading = false;
          });
        });
  }

  void _trainMl() {
    setState(() {
      loading = true;
      error = null;
    });

    api
        .trainMl(contamination: 0.10)
        .then((_) {
          _load();
        })
        .catchError((e) {
          setState(() {
            error = e.toString();
            loading = false;
          });
        });
  }

  Widget _metricCard(String title, String value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    if (metrics == null) {
      return const Text("No metrics available.");
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _metricCard("Precision", metrics!.precision.toStringAsFixed(3)),
        _metricCard("Recall", metrics!.recall.toStringAsFixed(3)),
        _metricCard("F1 Score", metrics!.f1.toStringAsFixed(3)),
        _metricCard("Accuracy", metrics!.accuracy.toStringAsFixed(3)),
        _metricCard(
          "False Positive Rate",
          metrics!.falsePositiveRate.toStringAsFixed(3),
        ),
        _metricCard(
          "False Negative Rate",
          metrics!.falseNegativeRate.toStringAsFixed(3),
        ),
        _metricCard("Specificity", metrics!.specificity.toStringAsFixed(3)),
        _metricCard("TP / FP", "${metrics!.tp} / ${metrics!.fp}"),
        _metricCard("TN / FN", "${metrics!.tn} / ${metrics!.fn}"),
      ],
    );
  }

  Widget _buildRocTable() {
    if (rocPoints.isEmpty) {
      return const Text("No ROC-style data available.");
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Threshold")),
          DataColumn(label: Text("TPR")),
          DataColumn(label: Text("FPR")),
        ],
        rows:
            rocPoints.map((point) {
              final threshold = (point["threshold"] as num?)?.toDouble() ?? 0.0;
              final tpr =
                  ((point["TPR"] ?? point["tpr"]) as num?)?.toDouble() ?? 0.0;
              final fpr =
                  ((point["FPR"] ?? point["fpr"]) as num?)?.toDouble() ?? 0.0;

              return DataRow(
                cells: [
                  DataCell(Text(threshold.toStringAsFixed(4))),
                  DataCell(Text(tpr.toStringAsFixed(4))),
                  DataCell(Text(fpr.toStringAsFixed(4))),
                ],
              );
            }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ML vs Baseline Metrics",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricsSection(),

                  const SizedBox(height: 24),

                  const Text(
                    "ROC-Style Threshold Sweep",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildRocTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
