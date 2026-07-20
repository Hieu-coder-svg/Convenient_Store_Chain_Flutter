import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/product_api_service.dart';

class ProductCatalogProvider extends ChangeNotifier {
  final ProductApiService _apiService;

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<ProductModel> _purchaseOrderProducts = [];
  bool _isLoadingPurchaseOrderProducts = false;
  String? _purchaseOrderProductsError;
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  ProductCatalogProvider(this._apiService);

  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  List<ProductModel> get purchaseOrderProducts => _purchaseOrderProducts;
  bool get isLoadingPurchaseOrderProducts => _isLoadingPurchaseOrderProducts;
  String? get purchaseOrderProductsError => _purchaseOrderProductsError;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;

  // --- Category Handlers ---
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _apiService.getCategories();
      _categories = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCategory(String name, String? description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCat = await _apiService.createCategory(name, description);
      _categories.add(newCat);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editCategory(int id, String name, String? description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.updateCategory(id, name, description);
      if (success) {
        final index = _categories.indexWhere((c) => c.categoryId == id);
        if (index != -1) {
          _categories[index] = _categories[index].copyWith(
            categoryName: name,
            description: description,
          );
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeCategory(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteCategory(id);
      if (success) {
        _categories.removeWhere((c) => c.categoryId == id);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reorderCategories(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final CategoryModel item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
    notifyListeners();
    // Ghi chú: Nếu backend hỗ trợ lưu DisplayOrder, ta sẽ gọi API cập nhật hàng loạt ở đây.
  }

  // --- Product Handlers ---
  Future<void> fetchProducts({
    String? search,
    int? categoryId,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pagedResult = await _apiService.getProducts(
        search: search,
        categoryId: categoryId,
        page: page,
        pageSize: 10,
      );

      _products = pagedResult.items;
      _currentPage = pagedResult.pageNumber;
      _totalCount = pagedResult.totalCount;
      _totalPages = (pagedResult.totalCount / 10).ceil();
      if (_totalPages == 0) _totalPages = 1;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads every product page for purchase-order selectors without changing
  /// the paginated product-management screen state.
  Future<void> fetchPurchaseOrderProducts({bool forceRefresh = false}) async {
    if (_isLoadingPurchaseOrderProducts) return;
    if (_purchaseOrderProducts.isNotEmpty && !forceRefresh) return;

    _isLoadingPurchaseOrderProducts = true;
    _purchaseOrderProductsError = null;
    notifyListeners();

    try {
      const pageSize = 100;
      var page = 1;
      var totalPages = 1;
      final allProducts = <ProductModel>[];

      do {
        final result = await _apiService.getProducts(
          page: page,
          pageSize: pageSize,
        );
        allProducts.addAll(result.items);
        totalPages = result.totalPages > 0 ? result.totalPages : 1;
        page++;
      } while (page <= totalPages);

      final uniqueProducts = <int, ProductModel>{};
      for (final product in allProducts) {
        uniqueProducts[product.productId] = product;
      }
      _purchaseOrderProducts = uniqueProducts.values.toList()
        ..sort((a, b) => a.productName.compareTo(b.productName));
    } catch (e) {
      _purchaseOrderProductsError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingPurchaseOrderProducts = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProd = await _apiService.createProduct(product);
      _products.add(newProd);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> editProduct(ProductModel product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.updateProduct(product);
      if (success) {
        final index = _products.indexWhere(
          (p) => p.productId == product.productId,
        );
        if (index != -1) {
          _products[index] = product;
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteProduct(id);
      if (success) {
        _products.removeWhere((p) => p.productId == id);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<int> getProductInventoryForBranch(int branchId, int productId) async {
    try {
      return await _apiService.getProductInventoryForBranch(
        branchId,
        productId,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<ProductModel> getProductById(int productId) async {
    try {
      return await _apiService.getProductById(productId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}
