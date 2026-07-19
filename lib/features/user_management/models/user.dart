class User {
  final int userId;
  final String username;
  final String fullName;
  final String email;
  final String? phone;
  final int roleId;
  final String roleName;
  final int? branchId;
  final String? branchName;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone,
    required this.roleId,
    required this.roleName,
    this.branchId,
    this.branchName,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: _parseInt(json['userId']) ?? 0,
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      roleId: _parseInt(json['roleId']) ?? 0,
      roleName: json['roleName']?.toString() ?? '',
      branchId: _parseInt(json['branchId']),
      branchName: json['branchName']?.toString(),
      isActive: _parseBool(json['isActive']),
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;

    return value?.toString().toLowerCase() == 'true';
  }
}