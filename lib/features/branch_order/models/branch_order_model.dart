import 'branch_order_detail_model.dart';

class BranchOrderModel {
  final int orderId;
  final int branchId;
  final String branchName;
  final int createdBy;
  final String creatorName;
  final String status;
  final DateTime orderDate;
  final DateTime updatedAt;
  final List<BranchOrderDetailModel> items;

  BranchOrderModel({
    required this.orderId,
    required this.branchId,
    required this.branchName,
    required this.createdBy,
    required this.creatorName,
    required this.status,
    required this.orderDate,
    required this.updatedAt,
    required this.items,
  });

  factory BranchOrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<BranchOrderDetailModel> items = itemsList
        .map((i) => BranchOrderDetailModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return BranchOrderModel(
      orderId: json['orderId'] ?? 0,
      branchId: json['branchId'] ?? 0,
      branchName: json['branchName'] ?? '',
      createdBy: json['createdBy'] ?? 0,
      creatorName: json['creatorName'] ?? '',
      status: json['status'] ?? 'Pending',
      orderDate: json['orderDate'] != null 
          ? DateTime.parse(json['orderDate']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'branchId': branchId,
      'branchName': branchName,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'status': status,
      'orderDate': orderDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  BranchOrderModel copyWith({
    int? orderId,
    int? branchId,
    String? branchName,
    int? createdBy,
    String? creatorName,
    String? status,
    DateTime? orderDate,
    DateTime? updatedAt,
    List<BranchOrderDetailModel>? items,
  }) {
    return BranchOrderModel(
      orderId: orderId ?? this.orderId,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
