class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
    this.fullName,
  });

  final int id;
  final String username;
  final String? fullName;
  final String role;
  final bool isActive;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  String get displayName {
    final name = fullName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return username;
  }

  // Role helpers

  bool get isAdmin => role == 'admin';

  bool get canManageInventory => role == 'admin' || role == 'inventory_officer';

  bool get canRunExperiments => role == 'admin' || role == 'safety_officer';

  bool get isReadOnly => !canManageInventory && !canRunExperiments;
}
