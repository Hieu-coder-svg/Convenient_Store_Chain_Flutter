import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/purchase_order_model.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final int poId;

  const PurchaseOrderDetailScreen({super.key, required this.poId});

  @override
  State<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PurchaseOrderProvider>();
      if (!provider.orders.any((order) => order.poId == widget.poId)) {
        provider.fetchOrderById(widget.poId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseOrderProvider>();
    PurchaseOrderModel? order;
    for (final candidate in provider.orders) {
      if (candidate.poId == widget.poId) order = candidate;
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn đặt hàng')),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(child: Text(provider.error ?? 'Không tìm thấy đơn hàng.')),
      );
    }

    final currentOrder = order;
    final isDirector =
        context.watch<AuthProvider>().currentUser?.roleName == 'Chain Director';
    final money = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: Text(currentOrder.purchaseOrderCode)),
      bottomNavigationBar: currentOrder.hasShortage && isDirector
          ? SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Tạo PO bổ sung phần giao thiếu'),
                onPressed: () =>
                    _createSupplementaryOrder(context, currentOrder),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => provider.fetchOrderById(widget.poId),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildResultCard(currentOrder),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Nhà cung cấp', currentOrder.supplierName),
                    _infoRow('Người lập', currentOrder.creatorName),
                    _infoRow(
                      'Ngày lập',
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(currentOrder.orderDate.toLocal()),
                    ),
                    _infoRow('Trạng thái', currentOrder.status),
                    _infoRow(
                      'Tổng tiền',
                      money.format(currentOrder.totalAmount),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chi tiết sản phẩm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...currentOrder.items.map(
              (item) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.inventory_2,
                    color: AppColors.primary,
                  ),
                  title: Text(item.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đặt: ${item.quantity} × ${money.format(item.unitPrice)}',
                      ),
                      if (currentOrder.hasReceipt)
                        Text(
                          'Thực nhận: ${item.quantityReceived}  •  Thiếu: ${item.shortageQuantity}',
                          style: TextStyle(
                            color: item.shortageQuantity > 0
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(money.format(item.lineTotal)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(PurchaseOrderModel order) {
    if (!order.hasReceipt) {
      return const Card(
        color: Color(0xFFFFF3E0),
        child: ListTile(
          leading: Icon(Icons.hourglass_top, color: Colors.orange),
          title: Text('Đang chờ nhân viên kho nhận hàng'),
          subtitle: Text('PO chưa có kết quả nhận hàng.'),
        ),
      );
    }
    if (order.hasShortage) {
      return const Card(
        color: Color(0xFFFFEBEE),
        child: ListTile(
          leading: Icon(Icons.warning_amber, color: Colors.red),
          title: Text('Đã đóng PO nhưng giao thiếu'),
          subtitle: Text(
            'Giám đốc chuỗi cần làm việc lại với nhà cung cấp và có thể tạo PO bổ sung.',
          ),
        ),
      );
    }
    return const Card(
      color: Color(0xFFE8F5E9),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: Text('Đã nhận đủ và hoàn tất'),
        subtitle: Text('Không cần thực hiện thêm thao tác nào cho PO này.'),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  void _createSupplementaryOrder(
    BuildContext context,
    PurchaseOrderModel order,
  ) {
    context.push(
      '/purchase-orders/create',
      extra: {
        'supplierId': order.supplierId,
        'items': order.items
            .where((item) => item.shortageQuantity > 0)
            .map(
              (item) => {
                'productId': item.productId,
                'quantity': item.shortageQuantity,
                'unitPrice': item.unitPrice,
              },
            )
            .toList(),
      },
    );
  }
}
