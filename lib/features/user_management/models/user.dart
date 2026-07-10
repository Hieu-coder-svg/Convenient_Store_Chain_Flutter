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
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      roleId: json['roleId'] ?? 0,
      roleName: json['roleName'] ?? '',
      branchId: json['branchId'],
      branchName: json['branchName'],
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
