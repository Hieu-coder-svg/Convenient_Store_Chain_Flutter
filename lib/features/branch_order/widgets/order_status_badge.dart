import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange.shade800;
        bgColor = Colors.orange.shade100;
        break;
      case 'fulfilled':
        color = Colors.green.shade800;
        bgColor = Colors.green.shade100;
        break;
      case 'cancelled':
        color = Colors.red.shade800;
        bgColor = Colors.red.shade100;
        break;
      default:
        color = Colors.grey.shade800;
        bgColor = Colors.grey.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
