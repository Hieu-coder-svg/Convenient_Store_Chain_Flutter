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
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/warehouse-inventory',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi tải danh sách kho tổng',
      );
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
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi tải danh sách kho chi nhánh',
      );
    }
  }

  // STOCK ADJUSTMENT
  Future<void> adjustStock(
    int branchId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      await _dioClient.dio.post(
        '/branches/$branchId/inventory/adjust',
        data: {'items': items},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi điều chỉnh tồn kho');
    }
  }

  // GOODS RECEIVING
  Future<void> receiveGoods(Map<String, dynamic> receiptData) async {
    try {
      await _dioClient.dio.post('/goods-receipts', data: receiptData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi tạo phiếu nhận hàng');
    }
  }
}
