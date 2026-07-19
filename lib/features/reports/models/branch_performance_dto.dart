class BranchPerformanceDto {
  final int branchId;
  final String branchName;
  final double totalRevenue;
  final int totalOrders;
  final int rank;

  BranchPerformanceDto({
    required this.branchId,
    required this.branchName,
    required this.totalRevenue,
    required this.totalOrders,
    required this.rank,
  });

  factory BranchPerformanceDto.fromJson(Map<String, dynamic> json) {
    return BranchPerformanceDto(
      branchId: json['branchId'] ?? 0,
      branchName: json['branchName'] ?? '',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }
}
