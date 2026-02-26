import 'package:flutter/material.dart';
import 'screens/items_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/anomalies_screen.dart';
import 'screens/metrics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory & Safety Management System',
      home: HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    ItemsListScreen(),
    DashboardScreen(),
    AnomaliesScreen(),
    MetricsScreen(),
  ];

  final _titles = const ["Items", "Dashboard", "Anomalies", "Metrics"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: "Items",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: "Anomalies",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Metrics",
          ),
        ],
      ),
    );
  }
}
