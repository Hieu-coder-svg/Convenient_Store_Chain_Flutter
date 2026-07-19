import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseOrderProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Đơn đặt hàng nhà cung cấp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchOrders(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/purchase-orders/create'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo Đơn'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lỗi: ${provider.error}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.fetchOrders(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : provider.orders.isEmpty
                  ? const Center(child: Text('Chưa có đơn đặt hàng nào'))
                  : RefreshIndicator(
                      onRefresh: provider.fetchOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.orders.length,
                        itemBuilder: (context, index) {
                          final order = provider.orders[index];
                          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate.toLocal());
                          final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order.totalAmount);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: order.status == 'Received' ? Colors.green : AppColors.primary,
                                child: const Icon(Icons.receipt_long, color: Colors.white),
                              ),
                              title: Text('PO #${order.poId} - ${order.supplierName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Ngày đặt: $formattedDate'),
                                  Text('Tổng tiền: $formattedAmount', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(order.status),
                                backgroundColor: order.status == 'Received' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                labelStyle: TextStyle(
                                  color: order.status == 'Received' ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => context.push('/purchase-orders/${order.poId}'),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
