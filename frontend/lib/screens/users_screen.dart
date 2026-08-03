import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../services/users_api.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({required this.client, super.key});

  final http.Client client;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const _roles = [
    'admin',
    'inventory_officer',
    'safety_officer',
    'viewer',
  ];

  late final UsersApi api;

  List<AuthUser> users = [];
  bool loading = true;
  bool creating = false;
  String? error;

  @override
  void initState() {
    super.initState();

    api = UsersApi(client: widget.client);

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await api.getUsers();

      if (!mounted) {
        return;
      }

      setState(() {
        users = result;
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

  Future<void> _showCreateUserDialog() async {
    final usernameController = TextEditingController();
    final fullNameController = TextEditingController();
    final passwordController = TextEditingController();

    String selectedRole = 'viewer';
    bool obscurePassword = true;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: !creating,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create user'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: 'Minimum 8 characters',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _roles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(_formatRole(role)),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      creating
                          ? null
                          : () {
                            Navigator.of(dialogContext).pop(false);
                          },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed:
                      creating
                          ? null
                          : () async {
                            final username = usernameController.text.trim();
                            final password = passwordController.text;

                            if (username.isEmpty) {
                              _showMessage(
                                dialogContext,
                                'Username is required.',
                              );
                              return;
                            }

                            if (password.length < 8) {
                              _showMessage(
                                dialogContext,
                                'Password must contain at least 8 characters.',
                              );
                              return;
                            }

                            setDialogState(() {
                              creating = true;
                            });

                            try {
                              await api.createUser(
                                username: username,
                                fullName: fullNameController.text,
                                password: password,
                                role: selectedRole,
                              );

                              if (!dialogContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop(true);
                            } catch (exception) {
                              if (!dialogContext.mounted) {
                                return;
                              }

                              _showMessage(dialogContext, exception.toString());
                            } finally {
                              creating = false;
                            }
                          },
                  child:
                      creating
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    usernameController.dispose();
    fullNameController.dispose();
    passwordController.dispose();

    if (created == true) {
      await _loadUsers();
    }
  }

  static String _formatRole(String role) {
    return role
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add User'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(error!),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        user.displayName.isEmpty
                            ? '?'
                            : user.displayName[0].toUpperCase(),
                      ),
                    ),
                    title: Text(user.displayName),
                    subtitle: Text(
                      '${user.username} • ${_formatRole(user.role)}',
                    ),
                    trailing: Chip(
                      label: Text(user.isActive ? 'Active' : 'Inactive'),
                      backgroundColor:
                          user.isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade200,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
