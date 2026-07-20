import 'daily_summary_model.dart';

class PeriodSummaryModel {
  final int totalInvoices;
  final double totalRevenue;
  final double totalDiscount;
  final double netRevenue;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailySummaryModel> dailyRecords;

  PeriodSummaryModel({
    required this.totalInvoices,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.netRevenue,
    required this.startDate,
    required this.endDate,
    required this.dailyRecords,
  });

  factory PeriodSummaryModel.fromJson(Map<String, dynamic> json) {
    return PeriodSummaryModel(
      totalInvoices: json['totalInvoices'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalDiscount: (json['totalDiscount'] ?? 0).toDouble(),
      netRevenue: (json['netRevenue'] ?? 0).toDouble(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : DateTime.now(),
      dailyRecords: (json['dailyRecords'] as List<dynamic>?)
              ?.map((e) => DailySummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
