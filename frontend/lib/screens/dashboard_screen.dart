import 'package:flutter/material.dart';
import '../services/evaluation_api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final api = EvaluationApi();

  String? error;
  bool loading = true;

  int safe = 0, warning = 0, unsafe = 0, mlAnom = 0;
  DateTime? lastUpdated;

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

    api.getEvalLots().then((rows) {
      int s = 0, w = 0, u = 0, a = 0;

      for (final r in rows) {
        final status = r.baselineStatus;

        if (status == "SAFE") s++;
        else if (status == "WARNING") w++;
        else if (status == "UNSAFE") u++;

        if (r.mlIsAnomaly == true) a++;
      }

      setState(() {
        safe = s;
        warning = w;
        unsafe = u;
        mlAnom = a;
        lastUpdated = DateTime.now();
        loading = false;
      });
    }).catchError((e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    });
  }

  String _formatTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // top bar
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
              const SizedBox(width: 12),
              if (lastUpdated != null)
                Text("Last updated: ${_formatTime(lastUpdated!)}"),
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

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _card("SAFE", safe),
              _card("WARNING", warning),
              _card("UNSAFE", unsafe),
              _card("ML anomalies", mlAnom),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(String title, int value) {
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("$value", style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}