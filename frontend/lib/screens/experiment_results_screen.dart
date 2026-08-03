import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/ml_metrics.dart';
import '../services/evaluation_api.dart';

class ExperimentResultsScreen extends StatefulWidget {
  const ExperimentResultsScreen({
    required this.client,
    required this.currentUser,
    super.key,
  });

  final http.Client client;
  final AuthUser currentUser;

  @override
  State<ExperimentResultsScreen> createState() =>
      _ExperimentResultsScreenState();
}

class _ExperimentResultsScreenState extends State<ExperimentResultsScreen> {
  late final EvaluationApi api;

  bool loading = true;
  String? error;

  MlMetrics? metrics;
  List<dynamic> rocPoints = [];
  Map<String, dynamic>? confusionMatrix;

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
    });

    MlMetrics? loadedMetrics;
    List<dynamic> loadedRocPoints = [];
    Map<String, dynamic>? loadedConfusionMatrix;
    String? partialError;

    try {
      loadedMetrics = await api.getMlVsBaselineMetrics();

      try {
        loadedRocPoints = await api.getRocSweep();
      } catch (exception) {
        partialError = exception.toString();
      }

      try {
        loadedConfusionMatrix = await api.getConfusionMatrix();
      } catch (exception) {
        partialError ??= exception.toString();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        metrics = loadedMetrics;
        rocPoints = loadedRocPoints;
        confusionMatrix = loadedConfusionMatrix;
        error = partialError;
        loading = false;
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        metrics = null;
        rocPoints = [];
        confusionMatrix = null;
        error = exception.toString();
        loading = false;
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
        error = exception.toString();
        loading = false;
      });
    }
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
    final currentMetrics = metrics;

    if (currentMetrics == null) {
      return const Text('No metrics are available.');
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _metricCard(
          'Precision',
          currentMetrics.precision.toStringAsFixed(3),
          color: Colors.blue.shade50,
        ),
        _metricCard(
          'Recall',
          currentMetrics.recall.toStringAsFixed(3),
          color: Colors.green.shade50,
        ),
        _metricCard(
          'F1 Score',
          currentMetrics.f1.toStringAsFixed(3),
          color: Colors.purple.shade50,
        ),
        _metricCard(
          'Accuracy',
          currentMetrics.accuracy.toStringAsFixed(3),
          color: Colors.teal.shade50,
        ),
        _metricCard('TP / FP', '${currentMetrics.tp} / ${currentMetrics.fp}'),
        _metricCard('TN / FN', '${currentMetrics.tn} / ${currentMetrics.fn}'),
      ],
    );
  }

  Widget _buildConfusionMatrix() {
    final currentMatrix = confusionMatrix;

    if (currentMatrix == null || currentMatrix['matrix'] == null) {
      return const Text('No confusion matrix is available.');
    }

    final matrix = currentMatrix['matrix'] as Map<String, dynamic>;
    final tp = matrix['TP'] ?? 0;
    final fp = matrix['FP'] ?? 0;
    final tn = matrix['TN'] ?? 0;
    final fn = matrix['FN'] ?? 0;

    Widget cell(String title, dynamic value, Color color) {
      return Container(
        width: 160,
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rows = Actual, Columns = Predicted',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            SizedBox(width: 90),
            SizedBox(
              width: 160,
              child: Center(
                child: Text(
                  'Predicted Unsafe',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: Center(
                child: Text(
                  'Predicted Safe',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 90,
              child: Text(
                'Actual Unsafe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            cell('TP', tp, Colors.green.shade100),
            const SizedBox(width: 12),
            cell('FN', fn, Colors.orange.shade100),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 90,
              child: Text(
                'Actual Safe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            cell('FP', fp, Colors.red.shade100),
            const SizedBox(width: 12),
            cell('TN', tn, Colors.blue.shade100),
          ],
        ),
      ],
    );
  }

  Widget _buildRocChart() {
    if (rocPoints.isEmpty) {
      return const Text('No ROC-style data is available.');
    }

    return Container(
      width: double.infinity,
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: CustomPaint(
        painter: RocChartPainter(rocPoints),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildRocTable() {
    if (rocPoints.isEmpty) {
      return const Text('No ROC-style data is available.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Threshold')),
          DataColumn(label: Text('TPR')),
          DataColumn(label: Text('FPR')),
        ],
        rows:
            rocPoints.map((point) {
              final threshold = (point['threshold'] as num?)?.toDouble() ?? 0.0;

              final tpr =
                  ((point['TPR'] ?? point['tpr']) as num?)?.toDouble() ?? 0.0;

              final fpr =
                  ((point['FPR'] ?? point['fpr']) as num?)?.toDouble() ?? 0.0;

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
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.red.shade50,
              ),
              child: Text(error!),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ML vs Baseline Metrics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricsSection(),
                  const SizedBox(height: 24),
                  const Text(
                    'Confusion Matrix',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildConfusionMatrix(),
                  const SizedBox(height: 24),
                  const Text(
                    'ROC Curve',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This chart shows the trade-off between the true positive '
                    'rate and false positive rate across different anomaly '
                    'thresholds.',
                  ),
                  const SizedBox(height: 12),
                  _buildRocChart(),
                  const SizedBox(height: 24),
                  const Text(
                    'ROC-Style Threshold Sweep Table',
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
  RocChartPainter(this.points);

  final List<dynamic> points;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftPadding = 40;
    const double bottomPadding = 30;
    const double topPadding = 10;
    const double rightPadding = 10;

    final chartWidth = size.width - leftPadding - rightPadding;

    final chartHeight = size.height - topPadding - bottomPadding;

    final axisPaint =
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 1.5;

    final linePaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    final diagonalPaint =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

    final pointPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    canvas.drawLine(
      const Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding),
      diagonalPaint,
    );

    final parsedPoints =
        points.map((point) {
          final fpr =
              ((point['FPR'] ?? point['fpr']) as num?)?.toDouble() ?? 0.0;

          final tpr =
              ((point['TPR'] ?? point['tpr']) as num?)?.toDouble() ?? 0.0;

          return Offset(
            leftPadding + fpr * chartWidth,
            topPadding + chartHeight - (tpr * chartHeight),
          );
        }).toList();

    if (parsedPoints.length > 1) {
      final path = Path()..moveTo(parsedPoints.first.dx, parsedPoints.first.dy);

      for (final point in parsedPoints.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, linePaint);
    }

    for (final point in parsedPoints) {
      canvas.drawCircle(point, 3.2, pointPaint);
    }

    const textStyle = TextStyle(fontSize: 11, color: Colors.black87);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawText(String text, Offset offset) {
      textPainter.text = TextSpan(text: text, style: textStyle);

      textPainter.layout();
      textPainter.paint(canvas, offset);
    }

    drawText('TPR', const Offset(4, 4));

    drawText(
      'FPR',
      Offset(leftPadding + chartWidth - 20, topPadding + chartHeight + 6),
    );

    drawText('0.0', Offset(leftPadding - 12, topPadding + chartHeight + 4));

    drawText(
      '1.0',
      Offset(leftPadding + chartWidth - 8, topPadding + chartHeight + 4),
    );

    drawText('1.0', Offset(8, topPadding - 2));
  }

  @override
  bool shouldRepaint(covariant RocChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
