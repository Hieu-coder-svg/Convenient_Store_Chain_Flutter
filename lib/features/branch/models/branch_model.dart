class BranchModel {
  final int branchId;
  final String branchName;
  final String? address;
  final String? phone;
  final bool isActive;

  BranchModel({
    required this.branchId,
    required this.branchName,
    this.address,
    this.phone,
    required this.isActive,
  });

  // Mã định dạng chi nhánh dạng BR-XXX
  String get formattedCode => 'BR-${branchId.toString().padLeft(3, '0')}';

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      branchId: json['branchId'] ?? json['id'] ?? 0,
      branchName: json['branchName'] ?? json['name'] ?? '',
      address: json['address'],
      phone: json['phone'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'branchName': branchName,
      'address': address,
      'phone': phone,
      'isActive': isActive,
    };
  }

  BranchModel copyWith({
    int? branchId,
    String? branchName,
    String? address,
    String? phone,
    bool? isActive,
  }) {
    return BranchModel(
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
    );
  }
}
