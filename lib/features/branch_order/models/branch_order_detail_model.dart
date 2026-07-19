class BranchOrderDetailModel {
  final int productId;
  final String productName;
  final int quantity;
  final String? unit;
  final String? importUnit;
  final int conversionFactor;

  BranchOrderDetailModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unit,
    this.importUnit,
    this.conversionFactor = 1,
  });

  factory BranchOrderDetailModel.fromJson(Map<String, dynamic> json) {
    return BranchOrderDetailModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'],
      importUnit: json['importUnit'],
      conversionFactor: json['conversionFactor'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unit': unit,
      'importUnit': importUnit,
      'conversionFactor': conversionFactor,
    };
  }
}
