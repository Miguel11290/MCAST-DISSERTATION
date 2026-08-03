import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/safety_rule.dart';
import '../services/rules_api.dart';

class SafetyRulesScreen extends StatefulWidget {
  const SafetyRulesScreen({required this.client, super.key});

  final http.Client client;

  @override
  State<SafetyRulesScreen> createState() => _SafetyRulesScreenState();
}

class _SafetyRulesScreenState extends State<SafetyRulesScreen> {
  late final RulesApi api;

  bool loading = true;
  String? error;
  RulesResponse? response;

  @override
  void initState() {
    super.initState();

    api = RulesApi(client: widget.client);

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
      final result = await api.getRules();

      if (!mounted) {
        return;
      }

      setState(() {
        response = result;
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
          if (error != null) ...[
            _messageCard(error!, Icons.error_outline, Colors.red.shade50),
            const SizedBox(height: 16),
          ],
          if (response != null) ...[
            _messageCard(
              response!.disclaimer,
              Icons.info_outline,
              Colors.blue.shade50,
            ),
            const SizedBox(height: 16),
            const Text(
              'Traceable Safety Rules',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Each rule exposes its purpose, authority, and configuration '
              'status. The prototype supports decisions; it does not make '
              'legal determinations.',
            ),
            const SizedBox(height: 16),
            ...response!.rules.map(_ruleCard),
            const SizedBox(height: 20),
            _configurationCard(response!.configuration),
          ],
          if (response == null && error == null)
            const Center(child: Text('No safety rules are available.')),
        ],
      ),
    );
  }

  Widget _messageCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }

  Widget _ruleCard(SafetyRule rule) {
    final severityColor = switch (rule.severity) {
      'UNSAFE' => Colors.red,
      'WARNING' => Colors.orange,
      _ => Colors.green,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(rule.severity),
                  backgroundColor: severityColor.withValues(alpha: 0.12),
                  side: BorderSide(color: severityColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(rule.description, style: const TextStyle(height: 1.4)),
            const Divider(height: 28),
            _detail('Source type', rule.sourceType),
            _detail('Source / authority', rule.source),
            _detail('Configurable', rule.configurable ? 'Yes' : 'No'),
            _detail(
              'Legal determination',
              rule.legalDetermination ? 'Yes' : 'No — decision support only',
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 165,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _configurationCard(Map<String, dynamic> config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Prototype Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SelectableText(
              config.entries
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join('\n'),
              style: const TextStyle(fontFamily: 'monospace', height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
