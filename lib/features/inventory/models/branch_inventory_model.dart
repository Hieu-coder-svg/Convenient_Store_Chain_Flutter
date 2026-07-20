class BranchInventoryModel {
  final int branchId;
  final String branchName;
  final int productId;
  final String productName;
  final String? barcode;
  final String? unit;
  final int quantity;
  final DateTime lastUpdated;

  BranchInventoryModel({
    required this.branchId,
    required this.branchName,
    required this.productId,
    required this.productName,
    this.barcode,
    this.unit,
    required this.quantity,
    required this.lastUpdated,
  });

  factory BranchInventoryModel.fromJson(Map<String, dynamic> json) {
    return BranchInventoryModel(
      branchId: json['branchId'],
      branchName: json['branchName'] ?? '',
      productId: json['productId'],
      productName: json['productName'] ?? '',
      barcode: json['barcode'],
      unit: json['unit'],
      quantity: json['quantity'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
