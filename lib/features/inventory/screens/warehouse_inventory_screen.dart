import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/inventory_provider.dart';

class WarehouseInventoryScreen extends StatefulWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  State<WarehouseInventoryScreen> createState() =>
      _WarehouseInventoryScreenState();
}

class _WarehouseInventoryScreenState extends State<WarehouseInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData({bool refresh = false}) {
    if (refresh) {
      _currentPage = 1;
    }
    context.read<InventoryProvider>().fetchWarehouseInventory(
      page: _currentPage,
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Kho Tổng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildPaginationControl(),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push(
            '/stock-adjustment',
            extra: {'isWarehouse': true},
          ).then((_) => _loadData(refresh: true));
        },
        icon: const Icon(Icons.inventory),
        label: const Text('Kiểm kê'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm sản phẩm (tên, mã vạch)...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _loadData(refresh: true);
            },
          ),
        ),
        onSubmitted: (_) => _loadData(refresh: true),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingWarehouse && _currentPage == 1) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.warehouseError != null &&
            provider.warehouseItems.isEmpty) {
          return Center(
            child: Text(
              provider.warehouseError!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (provider.warehouseItems.isEmpty) {
          return const Center(child: Text('Không tìm thấy dữ liệu tồn kho.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(refresh: true),
          child: ListView.separated(
            controller: _scrollController,
            itemCount: provider.warehouseItems.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = provider.warehouseItems[index];
              final bool isLowStock = item.quantity <= 10; // Threshold
              
              String secondaryText = '';
              if (item.conversionFactor > 1 && item.importUnit != null) {
                int boxes = item.quantity ~/ item.conversionFactor;
                int pieces = item.quantity % item.conversionFactor;
                secondaryText = '(~ $boxes ${item.importUnit} $pieces ${item.unit ?? ""})';
              }

              return ListTile(
                title: Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Barcode: ${item.barcode ?? "N/A"}\nCập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(item.lastUpdated.toLocal())}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.quantity} ${item.unit ?? ""}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.red : AppColors.primary,
                      ),
                    ),
                    if (secondaryText.isNotEmpty)
                      Text(secondaryText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (isLowStock)
                      const Text(
                        'Sắp hết',
                        style: TextStyle(color: Colors.red, fontSize: 10),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaginationControl() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        if (provider.warehouseTotalCount == 0) return const SizedBox.shrink();
        
        // Assume default pageSize = 10
        final int pageSize = 10;
        final int totalPages = (provider.warehouseTotalCount / pageSize).ceil();
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng: ${provider.warehouseTotalCount} sp',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadData();
                          }
                        : null,
                  ),
                  Text(
                    'Trang $_currentPage / $totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadData();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
