import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/health_response.dart';

class ApiService {
  Future<HealthResponse> getHealth(){
    final url = Uri.parse("${ApiConfig.baseUrl}/health");

    return http.get(url).then((response) {
      if(response.statusCode != 200){
        throw Exception("API error: ${response.statusCode}");
      }

      final data = json.decode(response.body);
      return HealthResponse.fromJson(data);
    });
  }
}