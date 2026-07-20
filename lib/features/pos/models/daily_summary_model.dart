class DailySummaryModel {
  final int totalInvoices;
  final double totalRevenue;
  final double totalDiscount;
  final double netRevenue;
  final DateTime? date; // Added to support charting by date

  DailySummaryModel({
    required this.totalInvoices,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.netRevenue,
    this.date,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      totalInvoices: json['totalInvoices'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0).toDouble(),
      netRevenue: (json['netRevenue'] ?? 0).toDouble(),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }
}
