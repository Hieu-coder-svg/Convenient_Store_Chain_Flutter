class InvoiceModel {
  final int invoiceId;
  final int branchId;
  final String branchName;
  final int staffId;
  final String staffName;
  final int? customerId;
  final String? customerName;
  final String? customerPhone;
  final DateTime invoiceDate;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentMethod;
  final String status;
  final int? loyaltyPointsEarned;
  final int? loyaltyPointsRedeemed;
  final int? customerLoyaltyBalance;
  final DateTime createdAt;
  final List<InvoiceDetailModel> items;

  InvoiceModel({
    required this.invoiceId,
    required this.branchId,
    required this.branchName,
    required this.staffId,
    required this.staffName,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.invoiceDate,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentMethod,
    required this.status,
    this.loyaltyPointsEarned,
    this.loyaltyPointsRedeemed,
    this.customerLoyaltyBalance,
    required this.createdAt,
    required this.items,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId'] ?? 0,
      branchId: json['branchId'] ?? 0,
      branchName: json['branchName'] ?? '',
      staffId: json['staffId'] ?? 0,
      staffName: json['staffName'] ?? '',
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      invoiceDate: DateTime.tryParse(json['invoiceDate'] ?? '') ?? DateTime.now(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      loyaltyPointsEarned: json['loyaltyPointsEarned'],
      loyaltyPointsRedeemed: json['loyaltyPointsRedeemed'],
      customerLoyaltyBalance: json['customerLoyaltyBalance'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List?)?.map((item) => InvoiceDetailModel.fromJson(item)).toList() ?? [],
    );
  }
}

class InvoiceDetailModel {
  final int productId;
  final String productName;
  final String? barcode;
  final int quantity;
  final double unitPrice;
  final double subTotal;

  InvoiceDetailModel({
    required this.productId,
    required this.productName,
    this.barcode,
    required this.quantity,
    required this.unitPrice,
    required this.subTotal,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      barcode: json['barcode'],
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      subTotal: (json['subTotal'] ?? 0).toDouble(),
    );
  }
}
