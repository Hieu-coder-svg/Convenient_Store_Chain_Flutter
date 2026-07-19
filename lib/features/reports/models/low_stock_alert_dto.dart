class LowStockAlertDto {
  final int productId;
  final String productName;
  final String categoryName;
  final String locationType;
  final String locationName;
  final int currentStock;
  final int minimumThreshold;

  LowStockAlertDto({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.locationType,
    required this.locationName,
    required this.currentStock,
    required this.minimumThreshold,
  });

  factory LowStockAlertDto.fromJson(Map<String, dynamic> json) {
    return LowStockAlertDto(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      categoryName: json['categoryName'] ?? '',
      locationType: json['locationType'] ?? '',
      locationName: json['locationName'] ?? '',
      currentStock: json['currentStock'] ?? 0,
      minimumThreshold: json['minimumThreshold'] ?? 0,
    );
  }
}
