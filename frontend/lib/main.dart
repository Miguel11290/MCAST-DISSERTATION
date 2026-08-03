import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/auth_user.dart';
import 'screens/about_screen.dart';
import 'screens/anomalies_screen.dart';
import 'screens/audit_logs_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/experiment_results_screen.dart';
import 'screens/items_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/metrics_screen.dart';
import 'screens/safety_rules_screen.dart';
import 'screens/users_screen.dart';
import 'services/auth_service.dart';
import 'services/authenticated_client.dart';

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
  late final AuthenticatedClient _apiClient;

  AuthUser? _currentUser;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();

    _authService = AuthService();

    _apiClient = AuthenticatedClient(
      authService: _authService,
      onUnauthorized: _handleUnauthorized,
    );

    _restoreSession();
  }

  Future<void> _handleUnauthorized() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = null;
    });
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
    try {
      final user = await _authService.getCurrentUser();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = user;
      });
    } on AuthException {
      await _authService.clearSession();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = null;
      });
    }
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
    _apiClient.close();
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

    return HomeShell(
      currentUser: user,
      apiClient: _apiClient,
      onLogout: _logout,
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.currentUser,
    required this.apiClient,
    required this.onLogout,
    super.key,
  });

  final AuthUser currentUser;
  final http.Client apiClient;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  bool _isLoggingOut = false;

  bool get _canViewAuditLogs {
    return widget.currentUser.isAdmin ||
        widget.currentUser.role == 'safety_officer';
  }

  List<Widget> get _pages => [
    ItemsListScreen(client: widget.apiClient, currentUser: widget.currentUser),
    DashboardScreen(client: widget.apiClient),
    AnomaliesScreen(client: widget.apiClient, currentUser: widget.currentUser),
    MetricsScreen(client: widget.apiClient, currentUser: widget.currentUser),
    ExperimentResultsScreen(
      client: widget.apiClient,
      currentUser: widget.currentUser,
    ),
    SafetyRulesScreen(client: widget.apiClient),
    if (_canViewAuditLogs) AuditLogsScreen(client: widget.apiClient),
    if (widget.currentUser.isAdmin) UsersScreen(client: widget.apiClient),
    const AboutScreen(),
  ];

  List<String> get _titles => [
    'Items',
    'Dashboard',
    'Anomalies',
    'Metrics',
    'Experiments',
    'Safety Rules',
    if (_canViewAuditLogs) 'Audit Logs',
    if (widget.currentUser.isAdmin) 'Users',
    'About',
  ];

  List<NavigationRailDestination> get _destinations => [
    const NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('Items'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.warning_amber_outlined),
      selectedIcon: Icon(Icons.warning_amber),
      label: Text('Anomalies'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: Text('Metrics'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.science_outlined),
      selectedIcon: Icon(Icons.science),
      label: Text('Experiments'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.rule_outlined),
      selectedIcon: Icon(Icons.rule),
      label: Text('Safety Rules'),
    ),
    if (_canViewAuditLogs)
      const NavigationRailDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: Text('Audit Logs'),
      ),
    if (widget.currentUser.isAdmin)
      const NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Users'),
      ),
    const NavigationRailDestination(
      icon: Icon(Icons.info_outline),
      selectedIcon: Icon(Icons.info),
      label: Text('About'),
    ),
  ];

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _initialForUser() {
    final displayName = widget.currentUser.displayName.trim();

    if (displayName.isEmpty) {
      return '?';
    }

    return displayName[0].toUpperCase();
  }

  Color _roleColor() {
    if (widget.currentUser.isAdmin) {
      return Colors.red;
    }

    if (widget.currentUser.canManageInventory) {
      return Colors.blue;
    }

    if (widget.currentUser.canRunExperiments) {
      return Colors.purple;
    }

    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final titles = _titles;
    final destinations = _destinations;

    final safeIndex = _index >= 0 && _index < pages.length ? _index : 0;

    final roleLabel = _formatRole(widget.currentUser.role);

    final roleColor = _roleColor();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: safeIndex,
            onDestinationSelected: (selectedIndex) {
              setState(() {
                _index = selectedIndex;
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
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  foregroundColor: roleColor,
                  child: Text(_initialForUser()),
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
            destinations: destinations,
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
                          titles[safeIndex],
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
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: roleColor.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                        itemBuilder: (context) {
                          return [
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
                          ];
                        },
                        child: CircleAvatar(
                          backgroundColor: roleColor.withValues(alpha: 0.15),
                          foregroundColor: roleColor,
                          child: Text(_initialForUser()),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: IndexedStack(index: safeIndex, children: pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
