import 'package:flutter/material.dart';

import 'models/auth_user.dart';
import 'screens/about_screen.dart';
import 'screens/anomalies_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/experiment_results_screen.dart';
import 'screens/items_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/metrics_screen.dart';
import 'screens/safety_rules_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService;

  AuthUser? _currentUser;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final hasSession = await _authService.hasSession();

      if (!hasSession) {
        return;
      }

      final user = await _authService.getCurrentUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = user;
      });
    } on AuthException {
      await _authService.clearSession();
    } catch (_) {
      // Keep the user logged out if session validation fails.
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
      }
    }
  }

  Future<void> _handleLoginSucceeded() async {
    final user = await _authService.getCurrentUser();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = null;
    });
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory & Safety Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isCheckingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _currentUser;

    if (user == null) {
      return LoginScreen(
        authService: _authService,
        onLoginSucceeded: _handleLoginSucceeded,
      );
    }

    return HomeShell(currentUser: user, onLogout: _logout);
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.currentUser,
    required this.onLogout,
    super.key,
  });

  final AuthUser currentUser;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _isLoggingOut = false;

  final List<Widget> _pages = const [
    ItemsListScreen(),
    DashboardScreen(),
    AnomaliesScreen(),
    MetricsScreen(),
    ExperimentResultsScreen(),
    SafetyRulesScreen(),
    AboutScreen(),
  ];

  final List<String> _titles = const [
    'Items',
    'Dashboard',
    'Anomalies',
    'Metrics',
    'Experiments',
    'Safety Rules',
    'About',
  ];

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || _isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.onLogout();
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map(
          (part) =>
              part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _formatRole(widget.currentUser.role);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              setState(() {
                _index = i;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: Colors.blue),
            leading: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Tooltip(
                message: '${widget.currentUser.displayName}\n$roleLabel',
                child: CircleAvatar(
                  child: Text(
                    widget.currentUser.displayName.isNotEmpty
                        ? widget.currentUser.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Sign out',
                    onPressed: _isLoggingOut ? null : _confirmLogout,
                    icon:
                        _isLoggingOut
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.logout),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Items'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning_amber),
                label: Text('Anomalies'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Metrics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science),
                label: Text('Experiments'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.rule_outlined),
                selectedIcon: Icon(Icons.rule),
                label: Text('Safety Rules'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: Text('About'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _titles[_index],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.currentUser.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            roleLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        tooltip: 'Account',
                        onSelected: (value) {
                          if (value == 'logout') {
                            _confirmLogout();
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.currentUser.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(roleLabel),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.logout),
                                  title: Text('Sign out'),
                                ),
                              ),
                            ],
                        child: const CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: IndexedStack(index: _index, children: _pages)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
