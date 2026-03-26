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

  Widget _metricCard(String title, String value, {Color? color}) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.grey.shade50,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Color(0x11000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
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
        _metricCard(
          "Precision",
          metrics!.precision.toStringAsFixed(3),
          color: Colors.blue.shade50,
        ),
        _metricCard(
          "Recall",
          metrics!.recall.toStringAsFixed(3),
          color: Colors.green.shade50,
        ),
        _metricCard(
          "F1 Score",
          metrics!.f1.toStringAsFixed(3),
          color: Colors.purple.shade50,
        ),
        _metricCard(
          "Accuracy",
          metrics!.accuracy.toStringAsFixed(3),
          color: Colors.teal.shade50,
        ),
        _metricCard(
          "False Positive Rate",
          metrics!.falsePositiveRate.toStringAsFixed(3),
          color: Colors.orange.shade50,
        ),
        _metricCard(
          "False Negative Rate",
          metrics!.falseNegativeRate.toStringAsFixed(3),
          color: Colors.red.shade50,
        ),
        _metricCard(
          "Specificity",
          metrics!.specificity.toStringAsFixed(3),
          color: Colors.indigo.shade50,
        ),
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

  Widget _buildRocChart() {
    if (rocPoints.isEmpty) {
      return const Text("No ROC-style data available.");
    }

    return Container(
      width: double.infinity,
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: CustomPaint(
        painter: RocChartPainter(rocPoints),
        child: Container(),
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
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.shade50,
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
                    "ROC Curve",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This chart shows the trade-off between true positive rate and false positive rate across thresholds.",
                  ),
                  const SizedBox(height: 12),
                  _buildRocChart(),

                  const SizedBox(height: 24),

                  const Text(
                    "ROC-Style Threshold Sweep Table",
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

class RocChartPainter extends CustomPainter {
  final List<dynamic> points;

  RocChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPad = 40;
    const double bottomPad = 30;
    const double topPad = 10;
    const double rightPad = 10;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    final axisPaint =
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 1.5;

    final linePaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    final diagPaint =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final pointPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    // axes
    canvas.drawLine(
      Offset(leftPad, topPad),
      Offset(leftPad, topPad + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPad, topPad + chartHeight),
      Offset(leftPad + chartWidth, topPad + chartHeight),
      axisPaint,
    );

    // diagonal reference
    canvas.drawLine(
      Offset(leftPad, topPad + chartHeight),
      Offset(leftPad + chartWidth, topPad),
      diagPaint,
    );

    final parsed =
        points.map((p) {
          final fpr = ((p["FPR"] ?? p["fpr"]) as num?)?.toDouble() ?? 0.0;
          final tpr = ((p["TPR"] ?? p["tpr"]) as num?)?.toDouble() ?? 0.0;
          return Offset(
            leftPad + fpr * chartWidth,
            topPad + chartHeight - (tpr * chartHeight),
          );
        }).toList();

    if (parsed.length > 1) {
      final path = Path()..moveTo(parsed.first.dx, parsed.first.dy);
      for (final pt in parsed.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    for (final pt in parsed) {
      canvas.drawCircle(pt, 3.2, pointPaint);
    }

    final textStyle = const TextStyle(fontSize: 11, color: Colors.black87);
    final tp = TextPainter(textDirection: TextDirection.ltr);

    void drawText(String text, Offset offset) {
      tp.text = TextSpan(text: text, style: textStyle);
      tp.layout();
      tp.paint(canvas, offset);
    }

    drawText("TPR", const Offset(4, 4));
    drawText(
      "FPR",
      Offset(leftPad + chartWidth - 20, topPad + chartHeight + 6),
    );
    drawText("0.0", Offset(leftPad - 12, topPad + chartHeight + 4));
    drawText("1.0", Offset(leftPad + chartWidth - 8, topPad + chartHeight + 4));
    drawText("1.0", Offset(8, topPad - 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
