class PurchaseOrderItemModel {
  final int productId;
  final String productName;
  final int quantity;
  final int quantityReceived;
  final double unitPrice;

  PurchaseOrderItemModel({
    required this.productId,
    this.productName = '',
    required this.quantity,
    this.quantityReceived = 0,
    required this.unitPrice,
  });

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      quantityReceived: json['quantityReceived'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  double get lineTotal => quantity * unitPrice;
  int get shortageQuantity =>
      quantityReceived >= quantity ? 0 : quantity - quantityReceived;
}
