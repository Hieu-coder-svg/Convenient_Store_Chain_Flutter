class NotificationModel {
  final int notificationId;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'],
      userId: json['userId'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  int? get purchaseOrderId {
    final text = '$title $message';
    final businessCodeMatch = RegExp(
      r'PO-\d{8}-(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (businessCodeMatch != null) {
      return int.tryParse(businessCodeMatch.group(1)!);
    }
    final legacyMatch = RegExp(
      r'PO #(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    return legacyMatch == null ? null : int.tryParse(legacyMatch.group(1)!);
  }
}
