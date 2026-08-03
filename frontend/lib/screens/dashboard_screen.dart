import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/evaluation_api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.client, super.key});

  final http.Client client;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final EvaluationApi api;

  bool loading = true;
  String? error;
  Map<String, dynamic> summary = const {};
  DateTime? lastUpdated;

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
      final result = await api.getOverviewSummary();

      if (!mounted) {
        return;
      }

      setState(() {
        summary = result;
        lastUpdated = DateTime.now();
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

  int _int(String key) {
    return (summary[key] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 12),
              if (lastUpdated != null)
                Text(
                  'Updated '
                  '${TimeOfDay.fromDateTime(lastUpdated!).format(context)}',
                ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            _notice(error!, Colors.red.shade50, Icons.error_outline),
          ],
          const SizedBox(height: 20),
          const Text(
            'Safety Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpi(
                'Total Lots',
                _int('total_lots'),
                Icons.inventory_2,
                Colors.blue.shade50,
              ),
              _kpi(
                'SAFE',
                _int('safe'),
                Icons.check_circle,
                Colors.green.shade50,
              ),
              _kpi(
                'WARNING',
                _int('warning'),
                Icons.warning_amber,
                Colors.orange.shade50,
              ),
              _kpi('UNSAFE', _int('unsafe'), Icons.error, Colors.red.shade50),
              _kpi(
                'ML Anomalies',
                _int('ml_anomalies'),
                Icons.psychology,
                Colors.purple.shade50,
              ),
              _kpi(
                'Conflict Rules Triggered',
                _int('conflicts'),
                Icons.link_off,
                Colors.red.shade100,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _insight(
                'Highest-risk location',
                summary['highest_risk_location']?.toString() ??
                    'No risk location identified',
                Icons.place_outlined,
              ),
              _insight(
                'Most-triggered rule',
                summary['most_triggered_rule']?.toString() ??
                    'No rules triggered',
                Icons.rule_outlined,
              ),
              _insight(
                'ML model',
                summary['model_trained'] == true
                    ? 'Trained and available'
                    : 'Not trained',
                Icons.model_training,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _notice(
            'Rule-based statuses represent explicit configured conditions. '
            'Machine-learning anomalies represent statistical unusualness '
            'and should be investigated rather than interpreted as legal or '
            'physical proof of danger.',
            Colors.blue.shade50,
            Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _kpi(String title, int value, IconData icon, Color background) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
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
            '$value',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _insight(String title, String value, IconData icon) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice(String text, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}
