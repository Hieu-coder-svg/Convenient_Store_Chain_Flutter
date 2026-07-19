class Branch {
  final int branchId;
  final String branchName;

  Branch({required this.branchId, required this.branchName});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['branchId'] ?? 0,
      branchName: json['branchName'] ?? '',
    );
  }
}