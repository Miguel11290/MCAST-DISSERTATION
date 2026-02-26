import 'package:flutter/material.dart';
import '../services/evaluation_api.dart';
import '../models/eval_row.dart';

class AnomaliesScreen extends StatefulWidget {
  const AnomaliesScreen({super.key});

  @override
  State<AnomaliesScreen> createState() => _AnomaliesScreenState();
}

class _AnomaliesScreenState extends State<AnomaliesScreen> {
  final api = EvaluationApi();
  String? error;
  bool loading = true;
  List<EvalRow> rows = [];

  @override
  void initState() {
    super.initState();

    api
        .getEvalLots()
        .then((data) {
          final only = data.where((r) => r.mlIsAnomaly == true).toList();
          setState(() {
            rows = only;
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
    if (rows.isEmpty) {
      return const Center(child: Text("No anomalies found. Train ML first."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Lot")),
          DataColumn(label: Text("Item")),
          DataColumn(label: Text("Score")),
          DataColumn(label: Text("ML signals")),
          DataColumn(label: Text("Baseline")),
        ],
        rows: rows.map((r) {
          return DataRow(cells: [
            DataCell(Text("${r.lotId}")),
            DataCell(Text("${r.itemId}")),
            DataCell(Text(r.mlScore?.toStringAsFixed(4) ?? "")),
            DataCell(Text((r.mlSignals ?? []).join(" | "))),
            DataCell(Text(r.baselineStatus)),
          ]);
      }).toList(),
    ),
    );
  }
}
