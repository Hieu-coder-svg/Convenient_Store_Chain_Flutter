class SupplierModel {
  final int supplierId;
  final String supplierName;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;

  SupplierModel({
    required this.supplierId,
    required this.supplierName,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    required this.isActive,
  });

  // Tạo mã hiển thị định dạng SUP-XXX
  String get formattedCode => 'SUP-${supplierId.toString().padLeft(3, '0')}';

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      supplierId: json['supplierId'] ?? json['id'] ?? 0,
      supplierName: json['supplierName'] ?? json['name'] ?? '',
      contactName: json['contactName'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'contactName': contactName,
      'phone': phone,
      'email': email,
      'address': address,
      'isActive': isActive,
    };
  }

  SupplierModel copyWith({
    int? supplierId,
    String? supplierName,
    String? contactName,
    String? phone,
    String? email,
    String? address,
    bool? isActive,
  }) {
    return SupplierModel(
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }
}
