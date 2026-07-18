class WarehouseInventoryModel {
  final int productId;
  final String productName;
  final String? barcode;
  final int quantity;
  final DateTime lastUpdated;

  WarehouseInventoryModel({
    required this.productId,
    required this.productName,
    this.barcode,
    required this.quantity,
    required this.lastUpdated,
  });

  factory WarehouseInventoryModel.fromJson(Map<String, dynamic> json) {
    return WarehouseInventoryModel(
      productId: json['productId'],
      productName: json['productName'] ?? '',
      barcode: json['barcode'],
      quantity: json['quantity'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
