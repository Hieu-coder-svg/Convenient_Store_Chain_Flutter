import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/branch_order_provider.dart';
import '../widgets/order_status_badge.dart';

class BranchOrderDetailScreen extends StatefulWidget {
  final int orderId;

  const BranchOrderDetailScreen({super.key, required this.orderId});

  @override
  State<BranchOrderDetailScreen> createState() =>
      _BranchOrderDetailScreenState();
}

class _BranchOrderDetailScreenState extends State<BranchOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchOrderProvider>().fetchOrderDetail(widget.orderId);
    });
  }

  void _showActionDialog(String action, Function() onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận $action'),
        content: Text('Bạn có chắc chắn muốn $action đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'duyệt' || action.contains('nhận hàng')
                  ? AppColors.primary
                  : AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveOrder() async {
    final provider = context.read<BranchOrderProvider>();
    final success = await provider.approveOrder(widget.orderId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duyệt đơn hàng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Lỗi khi duyệt đơn'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmReceived() async {
    final provider = context.read<BranchOrderProvider>();
    final success = await provider.confirmReceived(widget.orderId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác nhận nhận hàng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Lỗi khi xác nhận nhận hàng'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelOrder() async {
    final provider = context.read<BranchOrderProvider>();
    final success = await provider.cancelOrder(widget.orderId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hủy đơn hàng thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Lỗi khi hủy đơn'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final roleName = authProvider.currentUser?.roleName ?? '';
    final isWarehouseStaff = roleName == 'Warehouse Staff';
    final isStoreManager = roleName == 'Store Manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Chi tiết đơn #${widget.orderId}',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: Consumer<BranchOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedOrder == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.selectedOrder == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  ElevatedButton(
                    onPressed: () => provider.fetchOrderDetail(widget.orderId),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin đơn hàng.'),
            );
          }

          final isPending = order.status == 'Pending';

          return RefreshIndicator(
            onRefresh: () => provider.fetchOrderDetail(widget.orderId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin chung
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THÔNG TIN ĐƠN HÀNG',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Mã đơn:', 'BO-${order.orderId}'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Chi nhánh:', order.branchName),
                        const SizedBox(height: 8),
                        _buildInfoRow('Người tạo:', order.creatorName),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Ngày tạo:',
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(order.orderDate),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Trạng thái: ',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            OrderStatusBadge(status: order.status),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Danh sách sản phẩm
                  Text(
                    'DANH SÁCH SẢN PHẨM (${order.items.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, thickness: 0.5),
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mã SP: ${item.productId}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'SL: ${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nút hành động
                  () {
                    final statusLower = order.status.toLowerCase();
                    final isPending = statusLower == 'pending';
                    final isProcessing = statusLower == 'processing';

                    if ((isPending && (isWarehouseStaff || isStoreManager)) || (isProcessing && isStoreManager)) {
                      return Row(
                        children: [
                          if (isPending && isWarehouseStaff) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'DUYỆT ĐƠN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _showActionDialog(
                                        'duyệt',
                                        _approveOrder,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (isProcessing && isStoreManager) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'XÁC NHẬN NHẬN HÀNG',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _showActionDialog(
                                        'nhận hàng',
                                        _confirmReceived,
                                      ),
                              ),
                            ),
                          ],
                          if (isPending)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'HỦY ĐƠN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: provider.isLoading
                                    ? null
                                    : () => _showActionDialog('hủy', _cancelOrder),
                              ),
                            ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }(),

                  // Margin for bottom scrolling
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
