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

  List<EvalRow> all = [];
  List<EvalRow> filtered = [];

  String query = "";

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
        .getEvalLots()
        .then((data) {
          final only = data.where((r) => r.mlIsAnomaly == true).toList();
          setState(() {
            all = only;
            filtered = _applyFilter(only, query);
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

  List<EvalRow> _applyFilter(List<EvalRow> rows, String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) return rows;

    return rows.where((r) {
      final signals = (r.mlSignals ?? []).join(" ").toLowerCase();

      return signals.contains(qq) ||
          r.baselineStatus.toLowerCase().contains(qq) ||
          r.lotId.toString().contains(qq) ||
          r.itemId.toString().contains(qq) ||
          r.itemName.toLowerCase().contains(qq);
    }).toList();
  }

  void _onSearch(String v) {
    setState(() {
      query = v;
      filtered = _applyFilter(all, v);
    });
  }

  void _trainAndReload() {
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

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// Top bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    labelText: "Search anomalies (signals/status/id/name)",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),

              const SizedBox(width: 12),

              OutlinedButton.icon(
                onPressed: _trainAndReload,
                icon: const Icon(Icons.model_training),
                label: const Text("Train ML"),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// Error message
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

          /// Table
          if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  "No anomalies found. Click 'Train ML' then Refresh.",
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Lot")),
                      DataColumn(label: Text("Item")),
                      DataColumn(label: Text("Item Name")),
                      DataColumn(label: Text("Score")),
                      DataColumn(label: Text("Baseline")),
                      DataColumn(label: Text("Signals")),
                    ],
                    rows:
                        filtered.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text("${r.lotId}")),

                              DataCell(Text("${r.itemId}")),

                              DataCell(Text(r.itemName)),

                              DataCell(
                                Text(r.mlScore?.toStringAsFixed(4) ?? ""),
                              ),

                              DataCell(_statusChip(r.baselineStatus)),

                              DataCell(
                                SizedBox(
                                  width: 520,
                                  child: Text(
                                    (r.mlSignals ?? []).join(" | "),
                                    softWrap: true,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;

    if (status == "UNSAFE") {
      bg = Colors.red.shade100;
    } else if (status == "WARNING") {
      bg = Colors.orange.shade100;
    } else {
      bg = Colors.green.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(),
      ),
      child: Text(status),
    );
  }
}
