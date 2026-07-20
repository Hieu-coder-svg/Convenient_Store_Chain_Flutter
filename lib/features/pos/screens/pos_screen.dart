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
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
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
  
  int? _selectedCategoryId;
  int _currentProductPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductCatalogProvider>();
      provider.fetchCategories();
      provider.fetchProducts(page: 1, pageSize: 100);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ProductCatalogProvider>().fetchProducts(
            search: query,
            categoryId: _selectedCategoryId,
            page: 1,
            pageSize: 100,
          );
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
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

  void _handleBarcodeScan(String barcode, CartProvider cart) {
    if (barcode == '-1' || barcode.isEmpty) return;

    final products = context.read<ProductCatalogProvider>().products;
    final matchedProducts = products
        .where((p) => p.barcode == barcode)
        .toList();

    if (matchedProducts.isNotEmpty) {
      final product = matchedProducts.first;

      // Check if product is still active
      if (!product.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sản phẩm này đã ngừng kinh doanh!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      cart.addItem(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm: ${product.productName}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã vạch $barcode không tồn tại trong hệ thống!'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
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
                child: const Icon(
                  Icons.shopping_cart,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
        bottom: !isTablet
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(icon: Icon(Icons.inventory_2), text: 'Sản phẩm'),
                  Tab(icon: Icon(Icons.shopping_bag), text: 'Giỏ hàng'),
                ],
              )
            : null,
      ),
      drawer: const AppDrawer(),
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

  Widget _buildCategoryFilter(ProductCatalogProvider provider) {
    final categories = provider.categories;
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final isSelected = isAll 
              ? _selectedCategoryId == null 
              : _selectedCategoryId == category?.categoryId;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                isAll ? 'Tất cả' : category!.categoryName,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.outlineVariant,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryId = isAll ? null : category!.categoryId;
                    _currentProductPage = 0;
                  });
                  provider.fetchProducts(
                    categoryId: _selectedCategoryId,
                    search: _searchController.text,
                    page: 1,
                    pageSize: 100,
                  );
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                }
              },
            ),
          );
        },
      ),
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
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                ),
                tooltip: 'Quét mã vạch',
                onPressed: () async {
                  var res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleBarcodeScannerPage(),
                    ),
                  );
                  if (res is String && res != '-1' && res.isNotEmpty) {
                    _handleBarcodeScan(res, cart);
                  }
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: _onSearchChanged,
            onSubmitted: (value) {
              _handleBarcodeScan(value, cart);
              _searchController.clear();
            },
          ),
        ),
        // Category Filter
        Consumer<ProductCatalogProvider>(
          builder: (context, provider, child) {
            return _buildCategoryFilter(provider);
          },
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
                        onPressed: () => provider.fetchProducts(pageSize: 100),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              // Only show active products at POS
              final activeProducts = provider.products.where((p) => p.isActive).toList();

              if (activeProducts.isEmpty) {
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

                  // Paginated horizontal layout (2 rows)
                  const int rowsCount = 2;
                  final int itemsPerPage = crossAxisCount * rowsCount;
                  final int totalPages = (activeProducts.length / itemsPerPage).ceil();

                  return Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: totalPages,
                          onPageChanged: (page) {
                            setState(() {
                              _currentProductPage = page;
                            });
                          },
                          itemBuilder: (context, pageIndex) {
                            final startIndex = pageIndex * itemsPerPage;
                            final endIndex = (startIndex + itemsPerPage) > activeProducts.length
                                ? activeProducts.length
                                : (startIndex + itemsPerPage);
                            final pageProducts = activeProducts.sublist(startIndex, endIndex);

                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
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
                              itemCount: pageProducts.length,
                              itemBuilder: (context, index) {
                                final product = pageProducts[index];
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
                        ),
                      ),
                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16, top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              totalPages,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentProductPage == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentProductPage == index
                                      ? AppColors.primary
                                      : AppColors.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
