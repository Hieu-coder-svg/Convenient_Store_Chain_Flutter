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
    _scrollController.addListener(_onScroll);
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<InventoryProvider>();
      if (!provider.isLoadingWarehouse &&
          provider.warehouseItems.length < provider.warehouseTotalCount) {
        _currentPage++;
        _loadData();
      }
    }
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
          Expanded(child: _buildList()),
        ],
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
            itemCount:
                provider.warehouseItems.length +
                (provider.isLoadingWarehouse ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == provider.warehouseItems.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = provider.warehouseItems[index];
              final bool isLowStock = item.quantity <= 10; // Threshold

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
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isLowStock ? Colors.red : AppColors.primary,
                      ),
                    ),
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
}
