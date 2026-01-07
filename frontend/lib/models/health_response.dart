class HealthResponse {
  final String status;

  HealthResponse(this.status);

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(json['status'] ?? 'unknown');
  }
}