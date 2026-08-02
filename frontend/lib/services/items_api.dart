import "dart:convert";
import "package:http/http.dart" as http;
import '../core//api_config.dart';
import '../models/item.dart';

class ItemsApi {
  http.Client client = http.Client();

  void fetchItems({
    required void Function(List<Item>) onSuccess,
    required void Function(String) onError,
  }) {
    final url = Uri.parse("${ApiConfig.baseUrl}/items");

    client
        .get(url)
        .then((resp) {
          if (resp.statusCode == 200) {
            final List<dynamic> decoded = json.decode(resp.body);
            final items = decoded.map((e) => Item.fromJson(e)).toList();
            onSuccess(items);
          } else {
            onError("Failed: ${resp.statusCode} ${resp.body}");
          }
        })
        .catchError((e) {
          onError(e.toString());
        });
  }
}
