import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';

class BranchInventoryScreen extends StatefulWidget {
  const BranchInventoryScreen({super.key});

  @override
  State<BranchInventoryScreen> createState() => _BranchInventoryScreenState();
}

class _BranchInventoryScreenState extends State<BranchInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  int? _branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBranchIdAndData();
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadBranchIdAndData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      // Assuming user model has branchId or we can fetch it. For now, try to get from user object if available.
      // If not, we might need to select branch if Admin, or get from profile.
      // Let's assume Store Manager has branchId in user.branchId (if you added it)
      // If not available easily, we fallback to 1 for demo
      _branchId = 1; // TODO: Get actual branch ID from User Auth state.
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData({bool refresh = false}) {
    if (_branchId == null) return;
    if (refresh) {
      _currentPage = 1;
    }
    context.read<InventoryProvider>().fetchBranchInventory(
      _branchId!,
      page: _currentPage,
      search: _searchController.text,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<InventoryProvider>();
      if (!provider.isLoadingBranch &&
          provider.branchItems.length < provider.branchTotalCount) {
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
        title: const Text('Kho Chi Nhánh'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to Stock Adjustment
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('Kiểm Kê'),
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
        if (provider.isLoadingBranch && _currentPage == 1) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.branchError != null && provider.branchItems.isEmpty) {
          return Center(
            child: Text(
              provider.branchError!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (provider.branchItems.isEmpty) {
          return const Center(child: Text('Không tìm thấy dữ liệu tồn kho.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(refresh: true),
          child: ListView.separated(
            controller: _scrollController,
            itemCount:
                provider.branchItems.length +
                (provider.isLoadingBranch ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == provider.branchItems.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = provider.branchItems[index];
              final bool isLowStock = item.quantity <= 10;

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
