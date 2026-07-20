import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/purchase_order_model.dart';
import '../../../core/models/paged_result.dart';

class PurchaseOrderApiService {
  final DioClient _dioClient;

  PurchaseOrderApiService(this._dioClient);

  Future<PagedResult<PurchaseOrderModel>> getPurchaseOrders({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/purchase-orders',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data;
      if (data is List) {
        final items = data
            .map(
              (json) => PurchaseOrderModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList();
        return PagedResult<PurchaseOrderModel>(
          items: items,
          totalCount: items.length,
          pageNumber: 1,
          pageSize: items.isEmpty ? pageSize : items.length,
          totalPages: 1,
        );
      }
      if (data is! Map) {
        throw Exception('Dữ liệu danh sách PO trả về không hợp lệ.');
      }
      return PagedResult<PurchaseOrderModel>.fromJson(
        Map<String, dynamic>.from(data),
        (json) =>
            PurchaseOrderModel.fromJson(Map<String, dynamic>.from(json as Map)),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Không thể tải danh sách PO',
      );
    }
  }

  Future<PurchaseOrderModel> getPurchaseOrderById(int id) async {
    try {
      final response = await _dioClient.dio.get('/purchase-orders/$id');
      return PurchaseOrderModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load purchase order',
      );
    }
  }

  Future<PurchaseOrderModel> createPurchaseOrder(
    Map<String, dynamic> requestData,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        '/purchase-orders',
        data: requestData,
      );
      return PurchaseOrderModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create purchase order',
      );
    }
  }
}
