class UserStats {
  final int totalUsers;
  final int storeManagers;
  final int activeUsers;
  final int leaveRequests;

  UserStats({
    required this.totalUsers,
    required this.storeManagers,
    required this.activeUsers,
    required this.leaveRequests,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalUsers: json['totalUsers'] ?? 0,
      storeManagers: json['storeManagers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      leaveRequests: json['leaveRequests'] ?? 0,
    );
  }
}
