import 'purchase_order_item_model.dart';

class PurchaseOrderModel {
  final int poId;
  final int supplierId;
  final String supplierName;
  final int createdBy;
  final String creatorName;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final List<PurchaseOrderItemModel> items;

  PurchaseOrderModel({
    required this.poId,
    required this.supplierId,
    this.supplierName = '',
    required this.createdBy,
    this.creatorName = '',
    required this.orderDate,
    required this.totalAmount,
    this.status = 'Pending',
    this.items = const [],
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderModel(
      poId: json['poId'] ?? 0,
      supplierId: json['supplierId'] ?? 0,
      supplierName: json['supplierName'] ?? '',
      createdBy: json['createdBy'] ?? 0,
      creatorName: json['creatorName'] ?? '',
      orderDate: json['orderDate'] != null ? DateTime.parse(json['orderDate']) : DateTime.now(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pending',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => PurchaseOrderItemModel.fromJson(i)).toList()
          : [],
    );
  }
}
