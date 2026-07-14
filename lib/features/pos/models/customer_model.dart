class CustomerModel {
  final int customerId;
  final String fullName;
  final String? phone;
  final String? membershipId;
  final int loyaltyPoints;

  CustomerModel({
    required this.customerId,
    required this.fullName,
    this.phone,
    this.membershipId,
    required this.loyaltyPoints,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customerId'] ?? 0,
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      membershipId: json['membershipId'],
      loyaltyPoints: json['loyaltyPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'fullName': fullName,
      'phone': phone,
      'membershipId': membershipId,
      'loyaltyPoints': loyaltyPoints,
    };
  }
}
