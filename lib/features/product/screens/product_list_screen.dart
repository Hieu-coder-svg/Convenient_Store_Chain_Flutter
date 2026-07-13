import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/product_catalog_provider.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  bool? _selectedStatus;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = context.read<ProductCatalogProvider>();
      provider.fetchCategories();
      provider.fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<ProductCatalogProvider>().fetchProducts(
          search: query,
          categoryId: _selectedCategoryId,
        );
  }

  void _showCategoryFilterSheet(List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc theo danh mục',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategoryId == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                      context.read<ProductCatalogProvider>().fetchProducts(
                            search: _searchController.text,
                            categoryId: null,
                          );
                      Navigator.pop(context);
                    },
                  ),
                  ...categories.map(
                    (cat) => ChoiceChip(
                      label: Text(cat.categoryName),
                      selected: _selectedCategoryId == cat.categoryId,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryId = selected ? cat.categoryId : null;
                        });
                        context.read<ProductCatalogProvider>().fetchProducts(
                              search: _searchController.text,
                              categoryId: _selectedCategoryId,
                            );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc theo trạng thái',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Tất cả'),
                leading: Radio<bool?>(
                  value: null,
                  groupValue: _selectedStatus,
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Đang kinh doanh (Active)'),
                leading: Radio<bool?>(
                  value: true,
                  groupValue: _selectedStatus,
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Ngừng kinh doanh (Inactive)'),
                leading: Radio<bool?>(
                  value: false,
                  groupValue: _selectedStatus,
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.productName}" không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final provider = context.read<ProductCatalogProvider>();
                final success = await provider.removeProduct(product.productId);

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa sản phẩm thành công')),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductCatalogProvider>();
    // Lọc theo trạng thái local nếu backend chưa trả về dữ liệu tương ứng
    final products = provider.products.where((p) {
      if (_selectedStatus != null && p.isActive != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textSecondary),
          onPressed: () {},
        ),
        title: const Text(
          'Quản lý sản phẩm',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          // User avatar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, size: 20, color: Colors.grey),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchCategories();
          await provider.fetchProducts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              Container(
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
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm, SKU...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips Horizontal list
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      label: _selectedCategoryId == null
                          ? 'Categories'
                          : provider.categories.firstWhere((c) => c.categoryId == _selectedCategoryId).categoryName,
                      icon: Icons.expand_more,
                      onTap: () => _showCategoryFilterSheet(provider.categories),
                      isActive: _selectedCategoryId != null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: _selectedStatus == null
                          ? 'Status'
                          : (_selectedStatus! ? 'Active' : 'Inactive'),
                      icon: Icons.expand_more,
                      onTap: _showStatusFilterSheet,
                      isActive: _selectedStatus != null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Categories Admin',
                      icon: Icons.edit_note,
                      onTap: () {
                        context.go('/categories');
                      },
                      isActive: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Product Cards Grid
              if (provider.isLoading && products.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: CircularProgressIndicator(),
                ))
              else if (products.isEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 48),
                    child: const Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.outline),
                        SizedBox(height: 12),
                        Text(
                          'Không tìm thấy sản phẩm nào.',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1, // Bento grid style list
                    mainAxisExtent: 180,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                ),
              const SizedBox(height: 80), // Spacer for bottom bar
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          context.go('/products/add');
        },
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
            _buildBottomNavItem(Icons.home, 'Home', false, () {
              context.go('/home');
            }),
            _buildBottomNavItem(Icons.person, 'Staff', false, () {}),
            _buildBottomNavItem(Icons.schedule, 'Shifts', false, () {}),
            _buildBottomNavItem(Icons.warehouse, 'Stock', true, () {}),
            _buildBottomNavItem(Icons.shopping_cart, 'Orders', false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(
            color: product.isActive ? AppColors.primary : AppColors.error,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
              const SizedBox(width: 12),

              // Title and SKU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product.barcode ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quy cách: 1 ${product.importUnit ?? 'Thùng'} = ${product.conversionFactor} ${product.unit ?? 'Cái'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isActive
                      ? Colors.green.shade50
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: product.isActive ? Colors.green : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: product.isActive ? Colors.green.shade800 : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Prices Grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giá bán lẻ (Retail)',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${product.sellingPrice.toStringAsFixed(0)} VND',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giá nhập (Cost)',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${product.costPrice.toStringAsFixed(0)} VND',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh mục: ${product.categoryName}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.go('/products/edit/${product.productId}');
                      },
                      child: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _confirmDeleteProduct(product),
                      child: const Icon(Icons.delete, color: AppColors.error, size: 18),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
