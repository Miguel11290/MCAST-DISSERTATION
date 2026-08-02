import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final ApiService apiService = ApiService();
  String statusText = "Checking API...";

  @override
  void initState() {
    super.initState();
    checkApi();
  }

  void checkApi() {
    apiService
        .getHealth()
        .then((health) {
          if (!mounted) return;

          setState(() {
            statusText = "API Status: ${health.status}";
          });
        })
        .catchError((error) {
          if (!mounted) return;

          setState(() {
            statusText = "API Error: $error";
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connectivity Test")),
      body: Center(
        child: Text(statusText, style: const TextStyle(fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: checkApi,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
