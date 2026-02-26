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

  @override
  void initState() {
    super.initState();

    api.getEvalLots().then((rows) {
      int s = 0, w = 0, u = 0, a = 0;

      for (final r in rows) {
        if (r.baselineStatus == "SAFE"){
          s++;
        }else if (r.baselineStatus == "WARNING"){
          w++;
        }else if (r.baselineStatus == "UNSAFE"){
          u++;
        }

        if (r.mlIsAnomaly == true){
          a++;
        }
      }

      setState(() {
        safe = s; warning = w; unsafe = u; mlAnom = a;
        loading = false;
      });
    }).catchError((e) {
      setState(() { error = e.toString(); loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) return Center(child: Text(error!));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _card("SAFE", safe),
          _card("WARNING", warning),
          _card("UNSAFE", unsafe),
          _card("ML anomalies", mlAnom),
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