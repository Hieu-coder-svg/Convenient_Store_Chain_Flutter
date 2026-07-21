import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/purchase_order_provider.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage(1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) {
    return context.read<PurchaseOrderProvider>().fetchOrders(
      page: page,
      search: _searchController.text,
      status: _selectedStatus,
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _selectedStatus = null);
    _loadPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseOrderProvider>();
    final canCreate =
        context.watch<AuthProvider>().currentUser?.roleName == 'Chain Director';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn đặt hàng nhà cung cấp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoading
                ? null
                : () => _loadPage(provider.currentPage),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/purchase-orders/create');
                if (mounted) await _loadPage(1);
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn'),
            )
          : null,
      body: Column(
        children: [
          _buildFilters(provider),
          Expanded(child: _buildContent(provider)),
          if (!provider.isLoading && provider.error == null)
            _buildPagination(provider),
        ],
      ),
    );
  }

  Widget _buildFilters(PurchaseOrderProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadPage(1),
              decoration: InputDecoration(
                labelText: 'Tìm mã PO hoặc nhà cung cấp',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Tìm kiếm',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: provider.isLoading ? null : () => _loadPage(1),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tất cả')),
                DropdownMenuItem(value: 'Pending', child: Text('Chờ nhận')),
                DropdownMenuItem(value: 'Received', child: Text('Đã nhận')),
              ],
              onChanged: provider.isLoading
                  ? null
                  : (value) {
                      setState(() => _selectedStatus = value);
                      _loadPage(1);
                    },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Xóa bộ lọc',
            onPressed: provider.isLoading ? null : _clearFilters,
            icon: const Icon(Icons.filter_alt_off),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PurchaseOrderProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadPage(provider.currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (provider.orders.isEmpty) {
      return const Center(child: Text('Không tìm thấy đơn đặt hàng phù hợp.'));
    }

    final money = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return RefreshIndicator(
      onRefresh: () => _loadPage(provider.currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: provider.orders.length,
        itemBuilder: (context, index) {
          final order = provider.orders[index];
          final isReceived = order.status == 'Received';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isReceived ? Colors.green : AppColors.primary,
                child: const Icon(Icons.receipt_long, color: Colors.white),
              ),
              title: Text(
                '${order.purchaseOrderCode} - ${order.supplierName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate.toLocal())}',
                  ),
                  Text(
                    'Tổng tiền: ${money.format(order.totalAmount)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: Chip(
                label: Text(_statusLabel(order.status)),
                backgroundColor: (isReceived ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isReceived ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => context.push('/purchase-orders/${order.poId}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination(PurchaseOrderProvider provider) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Trang trước',
              onPressed: provider.currentPage > 1
                  ? () => _loadPage(provider.currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              'Trang ${provider.currentPage}/${provider.totalPages}  •  ${provider.totalCount} PO',
            ),
            IconButton(
              tooltip: 'Trang sau',
              onPressed: provider.currentPage < provider.totalPages
                  ? () => _loadPage(provider.currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ nhận';
      case 'Received':
        return 'Đã nhận';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
