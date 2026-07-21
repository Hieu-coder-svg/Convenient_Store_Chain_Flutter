import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class InventoryApiService {
  final DioClient _dioClient;

  InventoryApiService(this._dioClient);

  // WAREHOUSE INVENTORY
  Future<Map<String, dynamic>> getWarehouseInventory({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool lowStockOnly = false,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/warehouse-inventory',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          'lowStockOnly': lowStockOnly,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e) ?? 'Lỗi tải danh sách kho tổng');
    }
  }

  // BRANCH INVENTORY
  Future<Map<String, dynamic>> getBranchInventory(
    int branchId, {
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/branches/$branchId/inventory',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e) ?? 'Lỗi tải danh sách kho chi nhánh');
    }
  }

  // STOCK ADJUSTMENT
  Future<Map<String, dynamic>> adjustStock(
    int branchId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/branches/$branchId/inventory/adjust',
        data: {'items': items},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e) ?? 'Lỗi điều chỉnh tồn kho chi nhánh',
      );
    }
  }

  // GOODS RECEIVING
  Future<Map<String, dynamic>> receiveGoods(
    Map<String, dynamic> receiptData,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/goods-receipts',
        data: receiptData,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e) ?? 'Lỗi tạo phiếu nhận hàng');
    }
  }

  String? _getErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      return e.response?.data['message'] ??
          e.response?.data['Message'] ??
          e.response?.data['title'];
    } else if (e.response?.data is String) {
      return e.response?.data as String;
    }
    return null;
  }
}
