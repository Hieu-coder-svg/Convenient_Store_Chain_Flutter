import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/branch_model.dart';

class BranchApiService {
  final DioClient _dioClient;

  BranchApiService(this._dioClient);

  Future<List<BranchModel>> getBranches() async {
    try {
      final response = await _dioClient.dio.get('/branches');
      final List<dynamic> data = response.data;
      return data.map((json) => BranchModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể tải danh sách chi nhánh');
    }
  }

  Future<BranchModel> createBranch(BranchModel branch) async {
    try {
      final response = await _dioClient.dio.post(
        '/branches',
        data: branch.toJson(),
      );
      return BranchModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể tạo chi nhánh mới');
    }
  }

  Future<bool> updateBranch(BranchModel branch) async {
    try {
      await _dioClient.dio.put(
        '/branches/${branch.branchId}',
        data: branch.toJson(),
      );
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể cập nhật thông tin chi nhánh');
    }
  }

  Future<bool> deleteBranch(int id) async {
    try {
      await _dioClient.dio.delete('/branches/$id');
      return true;
    } on DioException catch (e) {
      throw _handleError(e, 'Không thể xóa chi nhánh');
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
