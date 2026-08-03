class AuditLog {
  const AuditLog({
    required this.id,
    required this.userId,
    required this.username,
    required this.action,
    required this.entityType,
    required this.description,
    required this.createdAt,
    this.entityId,
    this.oldValues,
    this.newValues,
  });

  final int id;
  final int userId;
  final String username;
  final String action;
  final String entityType;
  final int? entityId;
  final String description;
  final String? oldValues;
  final String? newValues;
  final DateTime createdAt;

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as int?,
      description: json['description'] as String,
      oldValues: json['old_values'] as String?,
      newValues: json['new_values'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
