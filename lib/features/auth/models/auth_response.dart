class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int userId;
  final String username;
  final String fullName;
  final int roleId;
  final String roleName;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.roleId,
    required this.roleName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      expiresIn: json['expiresIn'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      roleId: json['roleId'] ?? 0,
      roleName: json['roleName'] ?? '',
    );
  }
}
