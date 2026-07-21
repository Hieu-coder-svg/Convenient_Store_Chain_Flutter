import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../branch/providers/branch_provider.dart';
import '../providers/inventory_provider.dart';

class BranchInventoryScreen extends StatefulWidget {
  const BranchInventoryScreen({super.key});

  @override
  State<BranchInventoryScreen> createState() => _BranchInventoryScreenState();
}

class _BranchInventoryScreenState extends State<BranchInventoryScreen> {
  static const _pageSize = 10;
  final _searchController = TextEditingController();
  int _currentPage = 1;
  int? _branchId;

  bool get _canSelectBranch {
    final role = context.read<AuthProvider>().currentUser?.roleName;
    return role == 'Chain Director' || role == 'System Admin';
  }

  bool get _canAdjust {
    final role = context.read<AuthProvider>().currentUser?.roleName;
    return role == 'Store Manager';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      if (user.roleName == 'Chain Director' || user.roleName == 'System Admin') {
        await context.read<BranchProvider>().fetchBranches();
        if (!mounted) return;
        final activeBranches = context
            .read<BranchProvider>()
            .branches
            .where((branch) => branch.isActive)
            .toList();
        if (activeBranches.isNotEmpty) {
          setState(() => _branchId = activeBranches.first.branchId);
          _loadPage(1);
        }
      } else {
        setState(() => _branchId = user.branchId);
        if (_branchId != null) _loadPage(1);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPage(int page) async {
    if (_branchId == null) return;
    setState(() => _currentPage = page);
    await context.read<InventoryProvider>().fetchBranchInventory(
          _branchId!,
          page: page,
          search: _searchController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final branchProvider = context.watch<BranchProvider>();
    final totalPages = provider.branchTotalCount == 0
        ? 1
        : (provider.branchTotalCount / _pageSize).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tồn kho chi nhánh'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: provider.isLoadingBranch
                ? null
                : () => _loadPage(_currentPage),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _canAdjust && _branchId != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(
                  '/stock-adjustment',
                  extra: {'branchId': _branchId},
                );
                if (mounted) await _loadPage(_currentPage);
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Kiểm kê'),
            )
          : null,
      body: Column(
        children: [
          if (_canSelectBranch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DropdownButtonFormField<int>(
                initialValue: _branchId,
                decoration: const InputDecoration(
                  labelText: 'Chi nhánh',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: branchProvider.branches
                    .where((branch) => branch.isActive)
                    .map(
                      (branch) => DropdownMenuItem(
                        value: branch.branchId,
                        child: Text(branch.branchName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _branchId = value);
                  _loadPage(1);
                },
              ),
            ),
          _buildSearch(provider),
          Expanded(child: _buildContent(provider)),
          if (!provider.isLoadingBranch && provider.branchError == null)
            _buildPagination(provider, totalPages),
        ],
      ),
    );
  }

  Widget _buildSearch(InventoryProvider provider) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                  onPressed: provider.isLoadingBranch
                      ? null
                      : () {
                          _searchController.clear();
                          _loadPage(1);
                        },
                  icon: const Icon(Icons.clear),
                ),
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed:
                      provider.isLoadingBranch ? null : () => _loadPage(1),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _buildContent(InventoryProvider provider) {
    if (_branchId == null) {
      return const Center(child: Text('Tài khoản chưa được gán chi nhánh.'));
    }
    if (provider.isLoadingBranch) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.branchError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.branchError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadPage(_currentPage),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (provider.branchItems.isEmpty) {
      return const Center(child: Text('Không tìm thấy tồn kho chi nhánh.'));
    }

    return RefreshIndicator(
      onRefresh: () => _loadPage(_currentPage),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: provider.branchItems.length,
        itemBuilder: (context, index) {
          final item = provider.branchItems[index];
          final isLowStock = item.quantity <= 10;
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
              title: Text(item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Mã vạch: ${item.barcode ?? 'Chưa có'}\n'
                'Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(item.lastUpdated.toLocal())}',
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
                    const Text('Sắp hết hàng',
                        style: TextStyle(color: Colors.red, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination(InventoryProvider provider, int totalPages) => SafeArea(
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
                'Trang $_currentPage/$totalPages  •  ${provider.branchTotalCount} sản phẩm',
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
