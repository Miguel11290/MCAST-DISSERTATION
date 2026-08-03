import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_user.dart';
import '../models/item.dart';
import '../services/items_api.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({
    required this.client,
    required this.currentUser,
    super.key,
  });

  final http.Client client;
  final AuthUser currentUser;

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  late final ItemsApi api;

  List<Item> items = [];
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();

    api = ItemsApi(client: widget.client);

    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      loading = true;
      error = null;
    });

    await api.fetchItems(
      onSuccess: (data) {
        if (!mounted) {
          return;
        }

        setState(() {
          items = data;
          loading = false;
        });
      },
      onError: (message) {
        if (!mounted) {
          return;
        }

        setState(() {
          error = message;
          loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Error: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadItems,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 52),
            const SizedBox(height: 12),
            const Text('No items were found.'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (widget.currentUser.canManageInventory)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  // Add item screen/dialog will be connected here later.
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadItems,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.hazardClass ?? 'n/a'}'
                      ' • '
                      '${item.unit ?? 'n/a'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.maxSafeQuantity?.toString() ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (widget.currentUser.canManageInventory) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Edit item',
                            onPressed: () {
                              // Edit item screen/dialog will be connected here later.
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                        if (widget.currentUser.isAdmin)
                          IconButton(
                            tooltip: 'Delete item',
                            onPressed: () {
                              // Delete confirmation and API call will be added later.
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
