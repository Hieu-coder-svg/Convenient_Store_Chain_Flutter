import 'purchase_order_item_model.dart';

class PurchaseOrderModel {
  final int poId;
  final String purchaseOrderCode;
  final int supplierId;
  final String supplierName;
  final int createdBy;
  final String creatorName;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final int? receiptId;
  final List<PurchaseOrderItemModel> items;

  PurchaseOrderModel({
    required this.poId,
    required this.purchaseOrderCode,
    required this.supplierId,
    this.supplierName = '',
    required this.createdBy,
    this.creatorName = '',
    required this.orderDate,
    required this.totalAmount,
    this.status = 'Pending',
    this.receiptId,
    this.items = const [],
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    final poId = json['poId'] ?? 0;
    final orderDate = json['orderDate'] != null
        ? DateTime.parse(json['orderDate'])
        : DateTime.now();
    return PurchaseOrderModel(
      poId: poId,
      purchaseOrderCode:
          json['purchaseOrderCode'] ?? _buildCode(poId, orderDate),
      supplierId: json['supplierId'] ?? 0,
      supplierName: json['supplierName'] ?? '',
      createdBy: json['createdBy'] ?? 0,
      creatorName: json['creatorName'] ?? '',
      orderDate: orderDate,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pending',
      receiptId: json['receiptId'],
      items: json['items'] != null
          ? (json['items'] as List)
                .map((i) => PurchaseOrderItemModel.fromJson(i))
                .toList()
          : [],
    );
  }

  bool get hasReceipt => receiptId != null;
  bool get hasShortage =>
      hasReceipt && items.any((item) => item.shortageQuantity > 0);

  static String _buildCode(int id, DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'PO-$year$month$day-${id.toString().padLeft(6, '0')}';
  }
}
