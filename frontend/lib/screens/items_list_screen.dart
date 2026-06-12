import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/items_api.dart';

class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  final ItemsApi api = ItemsApi();
  List<Item> items = [];
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    api.fetchItems(
      onSuccess: (data) {
        if(!mounted) return;

        setState(() {
          items = data;
          loading = false;
        });
      },
      onError: (msg) {
        if(!mounted) return;
        
        setState(() {
          error = msg;
          loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text("Error: $error")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Items")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, idx) {
          final item = items[idx];
          return ListTile(
            title: Text(item.name),
            subtitle: Text(
              "${item.hazardClass ?? 'n/a'} | ${item.unit ?? 'n/a'}",
            ),
            trailing: Text(item.maxSafeQuantity?.toString() ?? "-"),
          );
        },
      ),
    );
  }
}
