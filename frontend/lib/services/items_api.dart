import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/item.dart';

class ItemsApi {
  ItemsApi({http.Client? client}) : client = client ?? http.Client();

  final http.Client client;

  Future<void> fetchItems({
    required void Function(List<Item>) onSuccess,
    required void Function(String) onError,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/items');

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body);

        final items =
            decoded
                .map((item) => Item.fromJson(item as Map<String, dynamic>))
                .toList();

        onSuccess(items);
      } else if (response.statusCode == 401) {
        onError('Your session has expired. Please sign in again.');
      } else if (response.statusCode == 403) {
        onError('You do not have permission to access this resource.');
      } else {
        onError(
          'Failed to load items: '
          '${response.statusCode} ${response.body}',
        );
      }
    } catch (error) {
      onError('Unable to connect to the server: $error');
    }
  }
}
