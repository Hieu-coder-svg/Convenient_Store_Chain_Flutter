import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/inventory_provider.dart';

class WarehouseInventoryScreen extends StatefulWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  State<WarehouseInventoryScreen> createState() =>
      _WarehouseInventoryScreenState();
}

class _WarehouseInventoryScreenState extends State<WarehouseInventoryScreen> {
  static const int _pageSize = 10;
  final _searchController = TextEditingController();
  int _currentPage = 1;
  bool _lowStockOnly = false;

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

  Future<void> _loadPage(int page) async {
    setState(() => _currentPage = page);
    await context.read<InventoryProvider>().fetchWarehouseInventory(
      page: page,
      search: _searchController.text,
      lowStockOnly: _lowStockOnly,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _loadPage(1);
  }

  void _toggleLowStockFilter(bool selected) {
    setState(() => _lowStockOnly = selected);
    _loadPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final totalPages = provider.warehouseTotalCount == 0
        ? 1
        : (provider.warehouseTotalCount / _pageSize).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tồn kho tổng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoadingWarehouse
                ? null
                : () => _loadPage(_currentPage),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(provider),
          Expanded(child: _buildContent(provider)),
          if (!provider.isLoadingWarehouse && provider.warehouseError == null)
            _buildPagination(provider, totalPages),
        ],
      ),
    );
  }

  Widget _buildSearch(InventoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadPage(1),
              decoration: InputDecoration(
                labelText: 'Tìm tên sản phẩm hoặc mã vạch',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.clear),
                      onPressed: provider.isLoadingWarehouse
                          ? null
                          : _clearSearch,
                    ),
                    IconButton(
                      tooltip: 'Tìm kiếm',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: provider.isLoadingWarehouse
                          ? null
                          : () => _loadPage(1),
                    ),
                  ],
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilterChip(
            selected: _lowStockOnly,
            avatar: const Icon(Icons.warning_amber, size: 18),
            label: const Text('Sắp hết hàng (≤ 50)'),
            onSelected: provider.isLoadingWarehouse
                ? null
                : _toggleLowStockFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(InventoryProvider provider) {
    if (provider.isLoadingWarehouse) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.warehouseError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.warehouseError!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadPage(_currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (provider.warehouseItems.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy sản phẩm trong kho tổng.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(_currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: provider.warehouseItems.length,
        itemBuilder: (context, index) {
          final item = provider.warehouseItems[index];
          final isLowStock = item.quantity <= 50;
          var convertedQuantity = '';
          if (item.conversionFactor > 1 && item.importUnit != null) {
            final importUnits = item.quantity ~/ item.conversionFactor;
            final baseUnits = item.quantity % item.conversionFactor;
            convertedQuantity =
                '~ $importUnits ${item.importUnit} $baseUnits ${item.unit ?? ''}';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isLowStock ? Colors.red : AppColors.primary)
                    .withValues(alpha: 0.12),
                child: Icon(
                  Icons.inventory_2,
                  color: isLowStock ? Colors.red : AppColors.primary,
                ),
              ),
              title: Text(
                item.productName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mã vạch: ${item.barcode ?? 'Chưa có'}'),
                  Text(
                    'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(item.lastUpdated.toLocal())}',
                  ),
                  if (convertedQuantity.isNotEmpty)
                    Text(
                      convertedQuantity,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.quantity} ${item.unit ?? ''}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? Colors.red : AppColors.primary,
                    ),
                  ),
                  if (isLowStock)
                    const Text(
                      'Sắp hết hàng',
                      style: TextStyle(color: Colors.red, fontSize: 11),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination(InventoryProvider provider, int totalPages) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Trang trước',
              onPressed: _currentPage > 1
                  ? () => _loadPage(_currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              'Trang $_currentPage/$totalPages  •  ${provider.warehouseTotalCount} sản phẩm',
            ),
            IconButton(
              tooltip: 'Trang sau',
              onPressed: _currentPage < totalPages
                  ? () => _loadPage(_currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
