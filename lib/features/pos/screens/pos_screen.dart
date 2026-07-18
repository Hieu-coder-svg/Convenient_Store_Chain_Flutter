import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../product/providers/product_catalog_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/product_search_tile.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary_bar.dart';
import '../widgets/customer_search_dialog.dart';
import '../../../../core/widgets/app_drawer.dart';
import 'dart:async';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductCatalogProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ProductCatalogProvider>().fetchProducts(search: query);
    });
  }

  void _showCustomerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final isTablet =
        MediaQuery.of(context).size.width >= 768; // Simple responsive check

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Máy tính tiền POS',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Badge(
                label: Text('${cart.totalQuantity}'),
                isLabelVisible: cart.totalQuantity > 0,
                child: const Icon(Icons.shopping_cart, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
        bottom: !isTablet
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(icon: Icon(Icons.inventory_2), text: 'Sản phẩm'),
                  Tab(icon: Icon(Icons.shopping_bag), text: 'Giỏ hàng'),
                ],
              )
            : null,
      ),
      body: isTablet
          ? _buildTabletLayout(cart, customerProvider)
          : _buildMobileLayout(cart, customerProvider),
    );
  }

  Widget _buildMobileLayout(
    CartProvider cart,
    CustomerProvider customerProvider,
  ) {
    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(cart),
              _buildCartList(cart, customerProvider),
            ],
          ),
        ),
        if (_tabController.index == 1)
          CartSummaryBar(
            totalItems: cart.totalItems,
            grandTotal: cart.grandTotal,
            onCheckout: () {
              if (cart.totalItems == 0) return;
              context.push('/checkout');
            },
          ),
      ],
    );
  }

  Widget _buildTabletLayout(
    CartProvider cart,
    CustomerProvider customerProvider,
  ) {
    return Row(
      children: [
        // Left: Products
        Expanded(flex: 5, child: _buildProductList(cart)),
        const VerticalDivider(width: 1, thickness: 1),
        // Right: Cart
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(child: _buildCartList(cart, customerProvider)),
              CartSummaryBar(
                totalItems: cart.totalItems,
                grandTotal: cart.grandTotal,
                onCheckout: () {
                  if (cart.totalItems == 0) return;
                  context.push('/checkout');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(CartProvider cart) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm tên hoặc mã sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        // Product Grid
        Expanded(
          child: Consumer<ProductCatalogProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: ${provider.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.fetchProducts(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.products.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không tìm thấy sản phẩm nào',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  if (constraints.maxWidth > 900) crossAxisCount = 5;

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final product = provider.products[index];
                      return ProductSearchTile(
                        product: product,
                        onAdd: () {
                          cart.addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm ${product.productName}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartList(CartProvider cart, CustomerProvider customerProvider) {
    return Column(
      children: [
        // Customer Selection
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: customerProvider.selectedCustomer == null
                    ? const Text(
                        'Khách hàng: Chưa chọn',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerProvider.selectedCustomer!.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '⭐ ${customerProvider.selectedCustomer!.loyaltyPoints} điểm',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
              TextButton(
                onPressed: _showCustomerDialog,
                child: Text(
                  customerProvider.selectedCustomer == null
                      ? 'Tìm khách'
                      : 'Đổi khách',
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Cart Items
        Expanded(
          child: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Giỏ hàng trống',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemTile(
                      item: item,
                      onIncrement: () => cart.updateQuantity(
                        item.productId,
                        item.quantity + 1,
                      ),
                      onDecrement: () => cart.updateQuantity(
                        item.productId,
                        item.quantity - 1,
                      ),
                      onQuantityChanged: (newQty) =>
                          cart.updateQuantity(item.productId, newQty),
                      onRemove: () => cart.removeItem(item.productId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
