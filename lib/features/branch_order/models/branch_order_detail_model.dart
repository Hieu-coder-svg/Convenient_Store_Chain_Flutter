class BranchOrderDetailModel {
  final int productId;
  final String productName;
  final int quantity;

  BranchOrderDetailModel({
    required this.productId,
    required this.productName,
    required this.quantity,
  });

  factory BranchOrderDetailModel.fromJson(Map<String, dynamic> json) {
    return BranchOrderDetailModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
    };
  }
}
