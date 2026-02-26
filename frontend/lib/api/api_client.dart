import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  ApiClient(this.baseUrl);

  Future<List<dynamic>> getEvalLots(){
    return http.get(Uri.parse('$baseUrl/eval/lots')).then((res){
      if(res.statusCode != 200){
        throw Exception('Failed: ${res.statusCode}');
      }
      return jsonDecode(res.body) as List<dynamic>;
    });
  }

  Future<Map<String, dynamic>> getMetrics() {
    return http.get(Uri.parse('$baseUrl/metrics/ml-vs-baseline')).then((res) {
      if (res.statusCode != 200) {
        throw Exception('Failed: ${res.statusCode}');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    });
  }

  Future<Map<String, dynamic>> getRocSweep() {
    return http.get(Uri.parse('$baseUrl/metrics/roc-sweep')).then((res) {
      if (res.statusCode != 200) {
        throw Exception('Failed: ${res.statusCode}');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    });
  }
}