import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/eval_row.dart';
import '../services/evaluation_api.dart';

class AnomaliesScreen extends StatefulWidget {
  const AnomaliesScreen({
    required this.client,
    required this.currentUser,
    super.key,
  });

  final http.Client client;
  final AuthUser currentUser;

  @override
  State<AnomaliesScreen> createState() => _AnomaliesScreenState();
}

class _AnomaliesScreenState extends State<AnomaliesScreen> {
  late final EvaluationApi api;

  String? error;
  bool loading = true;

  List<EvalRow> all = [];
  List<EvalRow> filtered = [];

  String query = '';

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

    try {
      final data = await api.getEvalLots();

      final anomalies = data.where((row) => row.mlIsAnomaly == true).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        all = anomalies;
        filtered = _applyFilter(anomalies, query);
        loading = false;
      });
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

  List<EvalRow> _applyFilter(List<EvalRow> rows, String searchTerm) {
    final queryValue = searchTerm.trim().toLowerCase();

    if (queryValue.isEmpty) {
      return rows;
    }

    return rows.where((row) {
      final signals = (row.mlSignals ?? []).join(' ').toLowerCase();

      final conflictsText =
          (row.conflictingLotIds ?? []).join(' ').toLowerCase();

      final triggeredRules = row.triggeredRuleIds.join(' ').toLowerCase();

      return signals.contains(queryValue) ||
          triggeredRules.contains(queryValue) ||
          row.baselineStatus.toLowerCase().contains(queryValue) ||
          row.lotId.toString().contains(queryValue) ||
          row.itemId.toString().contains(queryValue) ||
          row.itemName.toLowerCase().contains(queryValue) ||
          (row.location ?? '').toLowerCase().contains(queryValue) ||
          conflictsText.contains(queryValue) ||
          (queryValue.contains('conflict') &&
              row.conflictingLotIds != null &&
              row.conflictingLotIds!.isNotEmpty);
    }).toList();
  }

  void _onSearch(String value) {
    if (!mounted) {
      return;
    }

    setState(() {
      query = value;
      filtered = _applyFilter(all, value);
    });
  }

  Future<void> _trainAndReload() async {
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

  Color _rowColor(EvalRow row) {
    final hasConflict =
        row.conflictingLotIds != null && row.conflictingLotIds!.isNotEmpty;

    if (hasConflict || row.baselineStatus == 'UNSAFE') {
      return Colors.red.withValues(alpha: 0.08);
    }

    if (row.baselineStatus == 'WARNING') {
      return Colors.orange.withValues(alpha: 0.08);
    }

    return Colors.transparent;
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
              Expanded(
                child: TextField(
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    labelText:
                        'Search anomalies '
                        '(item, location, conflict, rule, signal...)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              if (widget.currentUser.canRunExperiments) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _trainAndReload,
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
          if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  widget.currentUser.canRunExperiments
                      ? 'No anomalies were found. You can retrain the model and refresh.'
                      : 'No anomalies were found.',
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
                      DataColumn(label: Text('Lot')),
                      DataColumn(label: Text('Item ID')),
                      DataColumn(label: Text('Item Name')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Score')),
                      DataColumn(label: Text('Baseline')),
                      DataColumn(label: Text('Triggered Rules')),
                      DataColumn(label: Text('Conflicts')),
                      DataColumn(label: Text('ML Explanation')),
                    ],
                    rows:
                        filtered.map((row) {
                          final hasConflict =
                              row.conflictingLotIds != null &&
                              row.conflictingLotIds!.isNotEmpty;

                          return DataRow(
                            color: WidgetStateProperty.all(_rowColor(row)),
                            cells: [
                              DataCell(Text('${row.lotId}')),
                              DataCell(Text('${row.itemId}')),
                              DataCell(Text(row.itemName)),
                              DataCell(Text(row.location ?? '-')),
                              DataCell(
                                Text(row.mlScore?.toStringAsFixed(4) ?? ''),
                              ),
                              DataCell(_statusChip(row.baselineStatus)),
                              DataCell(
                                SizedBox(
                                  width: 230,
                                  child: Text(
                                    row.triggeredRuleIds.isEmpty
                                        ? 'No deterministic rule'
                                        : row.triggeredRuleIds.join(', '),
                                  ),
                                ),
                              ),
                              DataCell(
                                hasConflict
                                    ? Text(
                                      '⚠ '
                                      '${row.conflictingLotIds!.join(', ')}',
                                    )
                                    : const Text('-'),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 540,
                                  child: Text(
                                    (row.mlSignals ?? []).join(' | '),
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
    Color background;

    if (status == 'UNSAFE') {
      background = Colors.red.shade100;
    } else if (status == 'WARNING') {
      background = Colors.orange.shade100;
    } else {
      background = Colors.green.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(),
      ),
      child: Text(status),
    );
  }
}
