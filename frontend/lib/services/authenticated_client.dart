import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({
    required AuthService authService,
    http.Client? innerClient,
    this.onUnauthorized,
  }) : _authService = authService,
       _innerClient = innerClient ?? http.Client();

  final AuthService _authService;
  final http.Client _innerClient;
  final Future<void> Function()? onUnauthorized;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _authService.getToken();

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.headers.putIfAbsent('Accept', () => 'application/json');

    final response = await _innerClient.send(request);

    if (response.statusCode == 401) {
      await _authService.clearSession();
      await onUnauthorized?.call();
    }

    return response;
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
