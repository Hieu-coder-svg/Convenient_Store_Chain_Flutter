import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import 'package:convenient_store_chain_flutter/core/models/paged_result.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductApiService {
  final DioClient _dioClient;

  ProductApiService(this._dioClient);

  // --- Category APIs ---
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dioClient.dio.get('/categories');
      final List<dynamic> data = response.data;
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể tải danh sách danh mục');
    }
  }

  Future<CategoryModel> createCategory(String name, String? description) async {
    try {
      final response = await _dioClient.dio.post(
        '/categories',
        data: {'categoryName': name, 'description': description},
      );
      return CategoryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể tạo danh mục mới');
    }
  }

  Future<bool> updateCategory(int id, String name, String? description) async {
    try {
      await _dioClient.dio.put(
        '/categories/$id',
        data: {'categoryName': name, 'description': description},
      );
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể cập nhật danh mục');
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      await _dioClient.dio.delete('/categories/$id');
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể xóa danh mục');
    }
  }

  // --- Product APIs ---
  Future<PagedResult<ProductModel>> getProducts({
    String? search,
    int? categoryId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'pageSize': pageSize,
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      final response = await _dioClient.dio.get(
        '/products',
        queryParameters: queryParams,
      );
      return PagedResult<ProductModel>.fromJson(
        response.data,
        (json) => ProductModel.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể tải danh sách sản phẩm');
    }
  }

  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dioClient.dio.get('/products/$id');
      return ProductModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể lấy thông tin sản phẩm');
    }
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await _dioClient.dio.post(
        '/products',
        data: product.toJson(),
      );
      return ProductModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể thêm sản phẩm mới');
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _dioClient.dio.put(
        '/products/${product.productId}',
        data: product.toJson(),
      );
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể cập nhật thông tin sản phẩm');
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await _dioClient.dio.delete('/products/$id');
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể xóa sản phẩm');
    }
  }

  Future<int> getProductInventoryForBranch(int branchId, int productId) async {
    try {
      final response = await _dioClient.dio.get('/branches/$branchId/inventory/$productId');
      return response.data['quantity'] ?? 0;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return 0; // If 404, it means no stock initialized, so quantity is 0
      }
      throw _handleError(e, 'Không thể tải tồn kho chi nhánh');
    }
  }

  // Helper error handler
  Exception _handleError(DioException e, String defaultMessage) {
    if (e.response != null && e.response?.data != null) {
      if (e.response?.data is Map) {
        final message =
            e.response?.data['message'] ?? e.response?.data['title'];
        if (message != null) {
          return Exception(message);
        }
      }
    }
    return Exception(defaultMessage);
  }
}
