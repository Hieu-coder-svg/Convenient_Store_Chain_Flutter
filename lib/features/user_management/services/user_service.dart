import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/paged_result.dart';
import '../models/user.dart';
import '../models/user_stats.dart';

class UserService {
  final DioClient _dioClient;

  UserService(this._dioClient);

  Future<PagedResult<User>> getUsers({int pageNumber = 1, int pageSize = 10, String? searchTerm}) async {
    try {
      final queryParams = {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
      };
      final response = await _dioClient.dio.get(ApiConstants.users, queryParameters: queryParams);
      return PagedResult<User>.fromJson(response.data['data'], (json) => User.fromJson(json));
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Lỗi tải danh sách người dùng');
      }
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<UserStats> getUserStats() async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.users}/stats');
      return UserStats.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Lỗi tải thống kê');
      }
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<void> activateUser(int id) async {
    try {
      await _dioClient.dio.put('${ApiConstants.users}/$id/activate');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Kích hoạt thất bại');
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  Future<void> deactivateUser(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConstants.users}/$id');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Khóa tài khoản thất bại');
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  Future<String> resetPassword(int id) async {
    try {
      final response = await _dioClient.dio.post('${ApiConstants.users}/$id/reset-password');
      return response.data['data']['newPassword'];
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Tạo mật khẩu thất bại');
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }
}
