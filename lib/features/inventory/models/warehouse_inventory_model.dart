class WarehouseInventoryModel {
  final int productId;
  final String productName;
  final String? barcode;
  final String? unit;
  final String? importUnit;
  final int conversionFactor;
  final int quantity;
  final DateTime lastUpdated;

  WarehouseInventoryModel({
    required this.productId,
    required this.productName,
    this.barcode,
    this.unit,
    this.importUnit,
    this.conversionFactor = 1,
    required this.quantity,
    required this.lastUpdated,
  });

  factory WarehouseInventoryModel.fromJson(Map<String, dynamic> json) {
    return WarehouseInventoryModel(
      productId: json['productId'],
      productName: json['productName'] ?? '',
      barcode: json['barcode'],
      unit: json['unit'],
      importUnit: json['importUnit'],
      conversionFactor: json['conversionFactor'] ?? 1,
      quantity: json['quantity'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
