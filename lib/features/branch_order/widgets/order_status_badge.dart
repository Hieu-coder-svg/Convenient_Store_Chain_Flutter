import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange.shade800;
        bgColor = Colors.orange.shade100;
        displayStatus = 'CHỜ DUYỆT';
        break;
      case 'processing':
        color = Colors.blue.shade800;
        bgColor = Colors.blue.shade100;
        displayStatus = 'ĐANG GIAO';
        break;
      case 'fulfilled':
        color = Colors.green.shade800;
        bgColor = Colors.green.shade100;
        displayStatus = 'HOÀN TẤT';
        break;
      case 'cancelled':
        color = Colors.red.shade800;
        bgColor = Colors.red.shade100;
        displayStatus = 'ĐÃ HỦY';
        break;
      default:
        color = Colors.grey.shade800;
        bgColor = Colors.grey.shade200;
        displayStatus = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
