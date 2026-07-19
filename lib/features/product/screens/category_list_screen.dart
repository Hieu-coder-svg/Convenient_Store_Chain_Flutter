import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../providers/product_catalog_provider.dart';
import '../models/category_model.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String _sortOrder = 'manual'; // 'manual', 'az', 'za', 'count_desc', 'count_asc'

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final provider = context.read<ProductCatalogProvider>();
      await provider.fetchCategories();
      await provider.fetchProducts(); // Load products to count them dynamically
    });
  }

  void _showAddEditCategoryDialog({CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.categoryName);
    final descController = TextEditingController(text: category?.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            category == null ? 'Thêm danh mục mới' : 'Chỉnh sửa danh mục',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  hintText: 'Nhập tên danh mục...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Nhập mô tả danh mục (tùy chọn)...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final desc = descController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập tên danh mục.'),
                    ),
                  );
                  return;
                }

                final provider = context.read<ProductCatalogProvider>();
                bool success;
                if (category == null) {
                  success = await provider.addCategory(
                    name,
                    desc.isEmpty ? null : desc,
                  );
                } else {
                  success = await provider.editCategory(
                    category.categoryId,
                    name,
                    desc.isEmpty ? null : desc,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          category == null
                              ? 'Đã thêm danh mục thành công'
                              : 'Đã cập nhật danh mục thành công',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.error ?? 'Thao tác thất bại'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa danh mục "${category.categoryName}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final provider = context.read<ProductCatalogProvider>();
                final success = await provider.removeCategory(
                  category.categoryId,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã xóa danh mục thành công'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.error ?? 'Không thể xóa danh mục',
                        ),
                        backgroundColor: AppColors.error,
                      ),
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

  // Lấy icon tượng trưng cho danh mục sản phẩm
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('uống') ||
        name.contains('nước') ||
        name.contains('bev') ||
        name.contains('drink')) {
      return Icons.local_drink;
    } else if (name.contains('ăn') ||
        name.contains('bánh') ||
        name.contains('food') ||
        name.contains('snack')) {
      return Icons.fastfood;
    } else if (name.contains('tươi') ||
        name.contains('sống') ||
        name.contains('thịt') ||
        name.contains('cá') ||
        name.contains('meal')) {
      return Icons.set_meal;
    } else if (name.contains('sữa') || name.contains('dairy')) {
      return Icons.egg_alt_outlined;
    } else {
      return Icons.shopping_basket;
    }
  }

  Color _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('uống') || name.contains('nước')) {
      return AppColors.primary;
    } else if (name.contains('ăn') || name.contains('bánh')) {
      return AppColors.secondary;
    } else if (name.contains('tươi') || name.contains('sống')) {
      return AppColors.error;
    } else {
      return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductCatalogProvider>();
    final rawCategories = provider.categories;
    final products = provider.products;

    // Tính toán số lượng sản phẩm động trên Frontend
    final List<CategoryModel> categories = rawCategories.map((c) {
      final count = products.where((p) => p.categoryId == c.categoryId).length;
      return c.copyWith(productCount: count);
    }).toList();

    // Sắp xếp theo cấu hình
    if (_sortOrder == 'az') {
      categories.sort((a, b) => a.categoryName.compareTo(b.categoryName));
    } else if (_sortOrder == 'za') {
      categories.sort((a, b) => b.categoryName.compareTo(a.categoryName));
    } else if (_sortOrder == 'count_desc') {
      categories.sort((a, b) => b.productCount.compareTo(a.productCount));
    } else if (_sortOrder == 'count_asc') {
      categories.sort((a, b) => a.productCount.compareTo(b.productCount));
    }

    // Tổng số sản phẩm đã phân loại (tổng hợp từ số lượng sản phẩm của các danh mục)
    int totalProducts = categories.fold(
      0,
      (sum, item) => sum + item.productCount,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Danh mục sản phẩm',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: provider.isLoading && categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await provider.fetchCategories();
                await provider.fetchProducts();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bento-style Overview Widgets
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                top: BorderSide(
                                  color: AppColors.primary,
                                  width: 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tổng danh mục',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  categories.length.toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                top: BorderSide(
                                  color: AppColors.secondary,
                                  width: 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sản phẩm đã phân loại',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalProducts.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Danh sách phân loại',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        PopupMenuButton<String>(
                          initialValue: _sortOrder,
                          onSelected: (value) {
                            setState(() {
                              _sortOrder = value;
                            });
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'manual',
                              child: Text('Thứ tự thủ công (Kéo thả)'),
                            ),
                            const PopupMenuItem(
                              value: 'az',
                              child: Text('Tên danh mục (A - Z)'),
                            ),
                            const PopupMenuItem(
                              value: 'za',
                              child: Text('Tên danh mục (Z - A)'),
                            ),
                            const PopupMenuItem(
                              value: 'count_desc',
                              child: Text('Số sản phẩm (Giảm dần)'),
                            ),
                            const PopupMenuItem(
                              value: 'count_asc',
                              child: Text('Số sản phẩm (Tăng dần)'),
                            ),
                          ],
                          child: Row(
                            children: [
                              Icon(
                                _sortOrder == 'manual' ? Icons.drag_handle : Icons.sort,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _sortOrder == 'manual'
                                    ? 'Sắp xếp'
                                    : (_sortOrder == 'az'
                                        ? 'Tên (A-Z)'
                                        : (_sortOrder == 'za'
                                            ? 'Tên (Z-A)'
                                            : (_sortOrder == 'count_desc'
                                                ? 'Sản phẩm (Giảm)'
                                                : 'Sản phẩm (Tăng)'))),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Reorderable List of Categories
                    if (categories.isEmpty)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 32),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.none,
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.dashboard_customize,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Không có danh mục nào.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: categories.length * 80.0 + 100.0,
                        child: _sortOrder == 'manual'
                            ? ReorderableListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: categories.length,
                                onReorder: provider.reorderCategories,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return _buildCategoryItem(
                                    category,
                                    index,
                                    isManual: true,
                                  );
                                },
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return _buildCategoryItem(
                                    category,
                                    index,
                                    isManual: false,
                                  );
                                },
                              ),
                      ),

                    const SizedBox(height: 24),
                    // Empty State Illustration Placeholder (Subtle)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBright,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.dashboard_customize,
                              color: AppColors.textSecondary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tùy chỉnh danh mục để tối ưu quy trình kiểm kho và bán hàng tại quầy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 80,
                    ), // Chừa trống cho FAB và Bottom Nav Bar
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddEditCategoryDialog(),
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
            _buildBottomNavItem(Icons.inventory, 'Inventory', true, () {}),
            _buildBottomNavItem(Icons.receipt_long, 'Sales', false, () {
              context.go('/home');
            }),
            _buildBottomNavItem(Icons.badge, 'Staff', false, () {}),
            _buildBottomNavItem(Icons.settings, 'Settings', false, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel category, int index, {required bool isManual}) {
    final color = _getCategoryColor(category.categoryName);
    final icon = _getCategoryIcon(category.categoryName);

    return Container(
      key: ValueKey(category.categoryId),
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isManual)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.drag_indicator,
                    color: AppColors.outline,
                  ),
                ),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
        title: Text(
          category.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${category.productCount} sản phẩm',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => _showAddEditCategoryDialog(
                category: category,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: () => _confirmDeleteCategory(category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
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
              color: isSelected
                  ? AppColors.onSecondaryFixed
                  : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppColors.onSecondaryFixed
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
