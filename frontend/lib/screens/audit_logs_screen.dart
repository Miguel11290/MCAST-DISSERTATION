import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/audit_log.dart';
import '../services/audit_api.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({required this.client, super.key});

  final http.Client client;

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  static const actions = ['', 'CREATE', 'UPDATE', 'DELETE'];

  static const entityTypes = ['', 'Item', 'InventoryLot'];

  late final AuditApi api;

  List<AuditLog> logs = [];
  bool loading = true;
  String? error;

  String selectedAction = '';
  String selectedEntityType = '';

  final usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    api = AuditApi(client: widget.client);

    _load();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await api.getAuditLogs(
        action: selectedAction,
        entityType: selectedEntityType,
        username: usernameController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        logs = result;
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

  void _clearFilters() {
    setState(() {
      selectedAction = '';
      selectedEntityType = '';
      usernameController.clear();
    });

    _load();
  }

  Color _actionColor(String action) {
    return switch (action) {
      'CREATE' => Colors.green,
      'UPDATE' => Colors.orange,
      'DELETE' => Colors.red,
      _ => Colors.grey,
    };
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${local.year}-'
        '${twoDigits(local.month)}-'
        '${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}:'
        '${twoDigits(local.second)}';
  }

  Map<String, dynamic>? _decodeValues(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> _showDetails(AuditLog log) async {
    final oldValues = _decodeValues(log.oldValues);
    final newValues = _decodeValues(log.newValues);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${log.action} ${log.entityType}'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('User', log.username),
                  _detailRow('Entity', log.entityType),
                  _detailRow('Entity ID', log.entityId?.toString() ?? '-'),
                  _detailRow('Timestamp', _formatDate(log.createdAt)),
                  _detailRow('Description', log.description),
                  if (oldValues != null) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Previous values',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _jsonPanel(oldValues),
                  ],
                  if (newValues != null) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'New values',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _jsonPanel(newValues),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

  Widget _jsonPanel(Map<String, dynamic> values) {
    final formatted = const JsonEncoder.withIndent('  ').convert(values);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: SelectableText(
        formatted,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedAction,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      actions
                          .map(
                            (action) => DropdownMenuItem(
                              value: action,
                              child: Text(
                                action.isEmpty ? 'All actions' : action,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAction = value ?? '';
                    });
                  },
                ),
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedEntityType,
                  decoration: const InputDecoration(
                    labelText: 'Entity type',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      entityTypes
                          .map(
                            (entity) => DropdownMenuItem(
                              value: entity,
                              child: Text(
                                entity.isEmpty ? 'All entities' : entity,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEntityType = value ?? '';
                    });
                  },
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              FilledButton.icon(
                onPressed: loading ? null : _load,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply'),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: loading ? null : _load,
                icon: const Icon(Icons.refresh),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(error!),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : logs.isEmpty
                    ? const Center(child: Text('No audit logs were found.'))
                    : Card(
                      child: ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final actionColor = _actionColor(log.action);

                          return ListTile(
                            onTap: () => _showDetails(log),
                            leading: CircleAvatar(
                              backgroundColor: actionColor.withValues(
                                alpha: 0.14,
                              ),
                              foregroundColor: actionColor,
                              child: Icon(switch (log.action) {
                                'CREATE' => Icons.add,
                                'UPDATE' => Icons.edit,
                                'DELETE' => Icons.delete,
                                _ => Icons.history,
                              }),
                            ),
                            title: Text(log.description),
                            subtitle: Text(
                              '${log.username} • '
                              '${log.entityType}'
                              '${log.entityId != null ? ' #${log.entityId}' : ''}'
                              ' • ${_formatDate(log.createdAt)}',
                            ),
                            trailing: Chip(
                              label: Text(log.action),
                              backgroundColor: actionColor.withValues(
                                alpha: 0.12,
                              ),
                              side: BorderSide(color: actionColor),
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
