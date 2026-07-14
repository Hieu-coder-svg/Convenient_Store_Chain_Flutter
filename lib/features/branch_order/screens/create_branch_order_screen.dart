import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../branch/providers/branch_provider.dart';
import '../../product/providers/product_catalog_provider.dart';
import '../../product/models/product_model.dart';
import '../providers/branch_order_provider.dart';
import '../widgets/order_item_card.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CreateBranchOrderScreen extends StatefulWidget {
  const CreateBranchOrderScreen({super.key});

  @override
  State<CreateBranchOrderScreen> createState() => _CreateBranchOrderScreenState();
}

class _CreateBranchOrderScreenState extends State<CreateBranchOrderScreen> {
  int? _selectedBranchId;
  final List<CartItem> _cartItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchProvider>().fetchBranches();
      context.read<ProductCatalogProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Chọn sản phẩm',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm tên hoặc mã sản phẩm...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        context.read<ProductCatalogProvider>().fetchProducts(search: value);
                      },
                    ),
                  ),
                  Expanded(
                    child: Consumer<ProductCatalogProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (provider.products.isEmpty) {
                          return const Center(child: Text('Không tìm thấy sản phẩm.'));
                        }

                        return ListView.builder(
                          controller: controller,
                          itemCount: provider.products.length,
                          itemBuilder: (context, index) {
                            final product = provider.products[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                                ),
                                title: Text(product.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                subtitle: Text('Giá: ${product.sellingPrice}đ'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                  onPressed: () {
                                    _addProductToCart(product);
                                    Navigator.pop(context);
                                  },
                                ),
                                onTap: () {
                                  _addProductToCart(product);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addProductToCart(ProductModel product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.product.productId == product.productId);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += 1;
      } else {
        _cartItems.add(CartItem(product: product));
      }
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQuantity = _cartItems[index].quantity + delta;
      if (newQuantity > 0) {
        _cartItems[index].quantity = newQuantity;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  Future<void> _submitOrder() async {
    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chi nhánh'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = context.read<BranchOrderProvider>();
    final itemsPayload = _cartItems.map((item) => {
      'productId': item.product.productId,
      'quantity': item.quantity,
    }).toList();

    final success = await provider.createOrder(_selectedBranchId!, itemsPayload);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo đơn hàng thành công!'), backgroundColor: Colors.green),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Lỗi khi tạo đơn hàng'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchProvider = context.watch<BranchProvider>();
    final orderProvider = context.watch<BranchOrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tạo đơn đặt hàng',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: Column(
        children: [
          // Header: Chọn chi nhánh & Tìm sản phẩm
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chi nhánh nhận hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('Chọn chi nhánh...'),
                      value: _selectedBranchId,
                      items: branchProvider.branches.map((branch) {
                        return DropdownMenuItem<int>(
                          value: branch.branchId,
                          child: Text(branch.branchName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBranchId = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showProductSearchSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Tìm sản phẩm để thêm vào đơn...', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Danh sách sản phẩm đã chọn
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.outline),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có sản phẩm nào',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vui lòng tìm và chọn sản phẩm',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return OrderItemCard(
                        product: item.product,
                        quantity: item.quantity,
                        onIncrement: () => _updateQuantity(index, 1),
                        onDecrement: () => _updateQuantity(index, -1),
                        onRemove: () => _removeItem(index),
                        onQuantityChanged: (newQuantity) {
                          setState(() {
                            _cartItems[index].quantity = newQuantity;
                          });
                        },
                      );
                    },
                  ),
          ),
          
          // Bottom Summary & Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng số mặt hàng:', style: TextStyle(fontSize: 14)),
                      Text('${_cartItems.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: (_cartItems.isEmpty || orderProvider.isLoading)
                          ? null
                          : _submitOrder,
                      child: orderProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'GỬI YÊU CẦU',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
