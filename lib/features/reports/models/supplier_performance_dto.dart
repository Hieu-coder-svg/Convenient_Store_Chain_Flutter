class SupplierPerformanceDto {
  final int supplierId;
  final String supplierName;
  final int totalOrders;
  final double totalValueProvided;
  final int onTimeDeliveries;
  final int lateDeliveries;
  final double deliveryPerformancePercentage;

  SupplierPerformanceDto({
    required this.supplierId,
    required this.supplierName,
    required this.totalOrders,
    required this.totalValueProvided,
    required this.onTimeDeliveries,
    required this.lateDeliveries,
    required this.deliveryPerformancePercentage,
  });

  factory SupplierPerformanceDto.fromJson(Map<String, dynamic> json) {
    return SupplierPerformanceDto(
      supplierId: json['supplierId'] ?? 0,
      supplierName: json['supplierName'] ?? '',
      totalOrders: json['totalOrders'] ?? 0,
      totalValueProvided: (json['totalValueProvided'] ?? 0).toDouble(),
      onTimeDeliveries: json['onTimeDeliveries'] ?? 0,
      lateDeliveries: json['lateDeliveries'] ?? 0,
      deliveryPerformancePercentage: (json['deliveryPerformancePercentage'] ?? 0).toDouble(),
    );
  }
}
