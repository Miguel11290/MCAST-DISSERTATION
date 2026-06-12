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

  int totalLots = 0;
  int safe = 0;
  int warning = 0;
  int unsafe = 0;
  int mlAnom = 0;
  int conflicts = 0;

  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    api
        .getEvalLots()
        .then((rows) {
          int total = rows.length;
          int s = 0;
          int w = 0;
          int u = 0;
          int a = 0;
          int c = 0;

          for (final r in rows) {
            if (r.baselineStatus == "SAFE") {
              s++;
            } else if (r.baselineStatus == "WARNING") {
              w++;
            } else if (r.baselineStatus == "UNSAFE") {
              u++;
            }

            if (r.mlIsAnomaly == true) {
              a++;
            }

            if (r.conflictingLotIds != null &&
                r.conflictingLotIds!.isNotEmpty) {
              c++;
            }
          }

          if (!mounted) return;

          setState(() {
            totalLots = total;
            safe = s;
            warning = w;
            unsafe = u;
            mlAnom = a;
            conflicts = c;
            lastUpdated = DateTime.now();
            loading = false;
          });
        })
        .catchError((e) {
          if (!mounted) return;

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
              if (lastUpdated != null)
                Text(
                  "Last updated: ${_formatTime(lastUpdated!)}",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 16),

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

          if (error != null) const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Safety Overview",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _kpiCard(
                        "Total Lots",
                        totalLots,
                        Icons.inventory_2,
                        Colors.blue.shade50,
                      ),
                      _kpiCard(
                        "SAFE",
                        safe,
                        Icons.check_circle,
                        Colors.green.shade50,
                      ),
                      _kpiCard(
                        "WARNING",
                        warning,
                        Icons.warning_amber,
                        Colors.orange.shade50,
                      ),
                      _kpiCard(
                        "UNSAFE",
                        unsafe,
                        Icons.error,
                        Colors.red.shade50,
                      ),
                      _kpiCard(
                        "ML Anomalies",
                        mlAnom,
                        Icons.psychology,
                        Colors.purple.shade50,
                      ),
                      _kpiCard(
                        "Storage Conflicts",
                        conflicts,
                        Icons.link_off,
                        Colors.red.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Summary",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _summaryPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, int value, IconData icon, Color bg) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
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
          Icon(icon),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "$value",
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade50,
      ),
      child: Text(
        "The dashboard summarises rule-based safety status, machine learning anomalies, "
        "and detected storage conflicts across the simulated inventory dataset. "
        "Unsafe lots indicate explicit rule violations, while ML anomalies represent "
        "unusual behavioural patterns identified by the anomaly detection model.",
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey.shade800,
          height: 1.5,
        ),
      ),
    );
  }
}
