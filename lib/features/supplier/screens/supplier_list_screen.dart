import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier_model.dart';
import '../widgets/add_edit_supplier_dialog.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool? _filterActive; // null = Tất cả, true = Đang hợp tác, false = Ngừng cung cấp

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<SupplierProvider>().fetchSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditSupplierDialog({SupplierModel? supplier}) {
    showDialog(
      context: context,
      builder: (context) => AddEditSupplierDialog(supplier: supplier),
    );
  }

  void _confirmDeleteSupplier(SupplierModel supplier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa nhà cung cấp "${supplier.supplierName}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final provider = context.read<SupplierProvider>();
                final success = await provider.removeSupplier(supplier.supplierId);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa nhà cung cấp thành công')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.error ?? 'Thao tác thất bại'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Lấy icon tượng trưng dựa trên tên nhà cung cấp
  IconData _getSupplierIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('coca') || lowerName.contains('pepsi') || lowerName.contains('shipping') || lowerName.contains('vận chuyển')) {
      return Icons.local_shipping;
    } else if (lowerName.contains('masan') || lowerName.contains('kho') || lowerName.contains('warehouse') || lowerName.contains('tổng')) {
      return Icons.warehouse;
    } else {
      return Icons.factory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    
    // Lọc nhà cung cấp theo tìm kiếm và bộ lọc hoạt động
    final filteredSuppliers = provider.suppliers.where((sup) {
      final matchesSearch = sup.supplierName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (sup.contactName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          sup.formattedCode.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _filterActive == null || sup.isActive == _filterActive;
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Nhà cung cấp',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: provider.isLoading && provider.suppliers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchSuppliers(),
              child: Column(
                children: [
                  // Sticky Search Bar Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    color: AppColors.background,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm nhà cung cấp...',
                          prefixIcon: Icon(Icons.search, color: AppColors.outline),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _buildFilterChip('Tất cả', null),
                        const SizedBox(width: 8),
                        _buildFilterChip('Đang hợp tác', true),
                        const SizedBox(width: 8),
                        _buildFilterChip('Ngừng cung cấp', false),
                      ],
                    ),
                  ),

                  // Supplier List Area
                  Expanded(
                    child: filteredSuppliers.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Column(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.outline),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không tìm thấy nhà cung cấp nào',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Thử lại với từ khóa khác hoặc thêm mới.'
                                        : 'Chưa có nhà cung cấp nào hoạt động.',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredSuppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = filteredSuppliers[index];
                              final icon = _getSupplierIcon(supplier.supplierName);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(icon, color: AppColors.primary, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  supplier.supplierName,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                ),
                                                if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.call, size: 14, color: AppColors.textSecondary),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        supplier.phone!,
                                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          supplier.address!,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                                                onPressed: () => _showAddEditSupplierDialog(supplier: supplier),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                                onPressed: () => _confirmDeleteSupplier(supplier),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: Colors.grey, thickness: 0.1),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: supplier.isActive
                                                  ? Colors.green.shade50
                                                  : AppColors.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              supplier.isActive ? 'Đang hợp tác' : 'Ngừng cung cấp',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: supplier.isActive ? Colors.green.shade800 : AppColors.error,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Mã: ${supplier.formattedCode}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.outline, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddEditSupplierDialog(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.inventory, 'Inventory', false, () {
              context.go('/products');
            }),
            _buildBottomNavItem(Icons.receipt_long, 'Sales', false, () {
              context.go('/home');
            }),
            _buildBottomNavItem(Icons.badge, 'Staff', true, () {}),
            _buildBottomNavItem(Icons.settings, 'Settings', false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool? value) {
    final isSelected = _filterActive == value;
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
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.outlineVariant),
      onSelected: (selected) {
        setState(() {
          _filterActive = value;
        });
      },
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: isSelected
                ? BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Icon(
              icon,
              color: isSelected ? AppColors.onSecondaryFixed : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.onSecondaryFixed : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
