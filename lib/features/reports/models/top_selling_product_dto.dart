class TopSellingProductDto {
  final int productId;
  final String productName;
  final String categoryName;
  final int totalQuantitySold;
  final double totalRevenue;

  TopSellingProductDto({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.totalQuantitySold,
    required this.totalRevenue,
  });

  factory TopSellingProductDto.fromJson(Map<String, dynamic> json) {
    return TopSellingProductDto(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      categoryName: json['categoryName'] ?? '',
      totalQuantitySold: json['totalQuantitySold'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}
