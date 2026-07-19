class RevenueDataPointDto {
  final String dateLabel;
  final double totalRevenue;
  final int orderCount;

  RevenueDataPointDto({
    required this.dateLabel,
    required this.totalRevenue,
    required this.orderCount,
  });

  factory RevenueDataPointDto.fromJson(Map<String, dynamic> json) {
    return RevenueDataPointDto(
      dateLabel: json['dateLabel'] ?? '',
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      orderCount: json['orderCount'] ?? 0,
    );
  }
}

class ChainRevenueDto {
  final double totalRevenuePeriod;
  final int totalOrdersPeriod;
  final List<RevenueDataPointDto> dataPoints;

  ChainRevenueDto({
    required this.totalRevenuePeriod,
    required this.totalOrdersPeriod,
    required this.dataPoints,
  });

  factory ChainRevenueDto.fromJson(Map<String, dynamic> json) {
    var list = json['dataPoints'] as List? ?? [];
    List<RevenueDataPointDto> dpList = list.map((i) => RevenueDataPointDto.fromJson(i)).toList();

    return ChainRevenueDto(
      totalRevenuePeriod: (json['totalRevenuePeriod'] ?? 0).toDouble(),
      totalOrdersPeriod: json['totalOrdersPeriod'] ?? 0,
      dataPoints: dpList,
    );
  }
}
