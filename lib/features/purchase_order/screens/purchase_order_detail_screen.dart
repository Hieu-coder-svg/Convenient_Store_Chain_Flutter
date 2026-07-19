import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderDetailScreen extends StatelessWidget {
  final int poId;

  const PurchaseOrderDetailScreen({super.key, required this.poId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseOrderProvider>();
    final order = provider.orders.firstWhere(
      (o) => o.poId == poId,
      orElse: () => throw Exception('Không tìm thấy đơn hàng'),
    );

    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate.toLocal());
    final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết PO #${order.poId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin chung
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THÔNG TIN ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Divider(),
                    _buildInfoRow('Nhà cung cấp:', order.supplierName),
                    _buildInfoRow('Người lập đơn:', order.creatorName),
                    _buildInfoRow('Ngày lập:', formattedDate),
                    _buildInfoRow('Trạng thái:', order.status, isStatus: true),
                    _buildInfoRow('Tổng tiền:', formattedAmount, isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Danh sách sản phẩm
            const Text('  CHI TIẾT SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...order.items.map((item) {
              final lineTotalFormatted = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item.lineTotal);
              final unitPriceFormatted = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item.unitPrice);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.background,
                    child: Icon(Icons.inventory_2, color: AppColors.primary),
                  ),
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SL: ${item.quantity}  x  $unitPriceFormatted'),
                  trailing: Text(
                    lineTotalFormatted, 
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          if (isStatus)
            Chip(
              label: Text(value),
              backgroundColor: value == 'Received' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: value == 'Received' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.red : AppColors.textPrimary,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
        ],
      ),
    );
  }
}
