import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/supplier_model.dart';

class SupplierApiService {
  final DioClient _dioClient;

  SupplierApiService(this._dioClient);

  Future<List<SupplierModel>> getSuppliers() async {
    try {
      final response = await _dioClient.dio.get('/suppliers');
      final List<dynamic> data = response.data;
      return data.map((json) => SupplierModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể tải danh sách nhà cung cấp');
    }
  }

  Future<SupplierModel> createSupplier(SupplierModel supplier) async {
    try {
      final response = await _dioClient.dio.post(
        '/suppliers',
        data: supplier.toJson(),
      );
      return SupplierModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể thêm nhà cung cấp mới');
    }
  }

  Future<bool> updateSupplier(SupplierModel supplier) async {
    try {
      await _dioClient.dio.put(
        '/suppliers/${supplier.supplierId}',
        data: supplier.toJson(),
      );
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể cập nhật nhà cung cấp');
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      await _dioClient.dio.delete('/suppliers/$id');
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể xóa nhà cung cấp');
    }
  }

  Exception _handleError(DioException e, String defaultMessage) {
    if (e.response != null && e.response?.data != null) {
      if (e.response?.data is Map) {
        final message = e.response?.data['message'] ?? e.response?.data['title'];
        if (message != null) {
          return Exception(message);
        }
      }
    }
    return Exception(defaultMessage);
  }
}
