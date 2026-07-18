import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/branch_order_provider.dart';
import '../widgets/order_status_badge.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';

class BranchOrderListScreen extends StatefulWidget {
  const BranchOrderListScreen({super.key});

  @override
  State<BranchOrderListScreen> createState() => _BranchOrderListScreenState();
}

class _BranchOrderListScreenState extends State<BranchOrderListScreen> {
  String _selectedStatus = 'All';
  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Fulfilled',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final orderProvider = context.read<BranchOrderProvider>();
    const int? fetchBranchId = null;
    final statusQuery = _selectedStatus == 'All' ? null : _selectedStatus;

    orderProvider.fetchOrders(branchId: fetchBranchId, status: statusQuery);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final roleName = authProvider.currentUser?.roleName ?? '';
    final isStoreManager = roleName == 'Store Manager';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Đơn đặt hàng nội bộ',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadOrders,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadOrders();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.background,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusOptions.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        status == 'All' ? 'Tất cả' : status,
                        status,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            Expanded(
              child: Consumer<BranchOrderProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
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
                          Text(
                            provider.error!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: _loadOrders,
                            child: const Text(
                              'Thử lại',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Lọc đơn hàng: Store Manager chỉ thấy đơn do mình tạo
                  final displayedOrders = isStoreManager
                      ? provider.orders
                            .where(
                              (o) =>
                                  o.createdBy ==
                                  authProvider.currentUser?.userId,
                            )
                            .toList()
                      : provider.orders;

                  if (displayedOrders.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 80),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: AppColors.outline,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Không có đơn hàng nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Chưa có đơn đặt hàng nào trong hệ thống.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            context.push('/branch-orders/${order.orderId}');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.local_shipping,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Đơn #${order.orderId}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    OrderStatusBadge(status: order.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(
                                  height: 1,
                                  color: Colors.grey,
                                  thickness: 0.1,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.storefront,
                                  'Chi nhánh',
                                  order.branchName,
                                ),
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  Icons.person_outline,
                                  'Người tạo',
                                  order.creatorName,
                                ),
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  'Ngày tạo',
                                  DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(order.orderDate),
                                ),
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  Icons.inventory_2_outlined,
                                  'Số lượng',
                                  '${order.items.length} mặt hàng',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isStoreManager
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () {
                context.push('/branch-orders/create');
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tạo đơn',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.outlineVariant,
      ),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : 'All';
        });
        _loadOrders();
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
