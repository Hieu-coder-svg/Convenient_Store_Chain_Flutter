import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderApiService {
  final DioClient _dioClient;

  PurchaseOrderApiService(this._dioClient);

  Future<List<PurchaseOrderModel>> getAllPurchaseOrders() async {
    try {
      final response = await _dioClient.dio.get('/purchase-orders');
      final Map<String, dynamic> data = response.data;
      final List<dynamic> items = data['items'] ?? [];
      return items.map((json) => PurchaseOrderModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load purchase orders');
    }
  }

  Future<PurchaseOrderModel> getPurchaseOrderById(int id) async {
    try {
      final response = await _dioClient.dio.get('/purchase-orders/$id');
      return PurchaseOrderModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load purchase order');
    }
  }

  Future<PurchaseOrderModel> createPurchaseOrder(Map<String, dynamic> requestData) async {
    try {
      final response = await _dioClient.dio.post('/purchase-orders', data: requestData);
      return PurchaseOrderModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create purchase order');
    }
  }
}
