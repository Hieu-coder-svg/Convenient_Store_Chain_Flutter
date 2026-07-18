import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/branch_order_model.dart';

class BranchOrderApiService {
  final DioClient _dioClient;

  BranchOrderApiService(this._dioClient);

  Future<List<BranchOrderModel>> getOrders({
    int? branchId,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (branchId != null) queryParams['branchId'] = branchId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _dioClient.dio.get(
        ApiConstants.branchOrders,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => BranchOrderModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<BranchOrderModel> getOrderById(int id) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.branchOrders}/$id',
      );
      return BranchOrderModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> createOrder(
    int branchId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final payload = {'branchId': branchId, 'items': items};
      await _dioClient.dio.post(ApiConstants.branchOrders, data: payload);
      return true;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> approveOrder(int id) async {
    try {
      await _dioClient.dio.put('${ApiConstants.branchOrders}/$id/approve');
      return true;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<bool> cancelOrder(int id) async {
    try {
      await _dioClient.dio.put('${ApiConstants.branchOrders}/$id/cancel');
      return true;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final message = data is Map
          ? data['message']
          : 'Error: ${e.response?.statusCode}';
      return Exception(message ?? 'Unknown server error');
    } else {
      return Exception('Network error or server unreachable');
    }
  }
}
