class SafetyRule {
  final String id;
  final String name;
  final String severity;
  final String description;
  final String sourceType;
  final String source;
  final bool configurable;
  final bool legalDetermination;

  const SafetyRule({
    required this.id,
    required this.name,
    required this.severity,
    required this.description,
    required this.sourceType,
    required this.source,
    required this.configurable,
    required this.legalDetermination,
  });

  factory SafetyRule.fromJson(Map<String, dynamic> json) {
    return SafetyRule(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      sourceType: json['source_type']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      configurable: json['configurable'] == true,
      legalDetermination: json['legal_determination'] == true,
    );
  }
}
