import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/models/paged_result.dart';
import '../models/user.dart';
import '../models/user_stats.dart';

class UserService {
  final DioClient _dioClient;

  UserService(this._dioClient);

  String _errorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final messages = <String>[];
      final message = data['message'] ?? data['Message'] ?? data['title'];
      if (message is String && message.trim().isNotEmpty) {
        messages.add(message.trim());
      }
      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List) {
            messages.addAll(
              value.whereType<String>().where((item) => item.trim().isNotEmpty),
            );
          } else if (value is String && value.trim().isNotEmpty) {
            messages.add(value.trim());
          }
        }
      }
      if (messages.isNotEmpty) return messages.toSet().join('\n');
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return fallback;
  }

  Future<PagedResult<User>> getUsers({
    int pageNumber = 1,
    int pageSize = 10,
    String? searchTerm,
  }) async {
    try {
      final queryParams = {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (searchTerm != null && searchTerm.isNotEmpty)
          'searchTerm': searchTerm,
      };
      final response = await _dioClient.dio.get(
        ApiConstants.users,
        queryParameters: queryParams,
      );
      return PagedResult<User>.fromJson(
        response.data['data'],
        (json) => User.fromJson(json),
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(_errorMessage(e, 'Lỗi tải danh sách người dùng'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
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
        throw Exception(_errorMessage(e, 'Lỗi tải thống kê'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<void> activateUser(int id) async {
    try {
      await _dioClient.dio.put('${ApiConstants.users}/$id/activate');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(_errorMessage(e, 'Kích hoạt thất bại'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  Future<void> deactivateUser(int id) async {
    try {
      await _dioClient.dio.delete('${ApiConstants.users}/$id');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(_errorMessage(e, 'Khóa tài khoản thất bại'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  Future<String> resetPassword(int id) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.users}/$id/reset-password',
      );
      return response.data['data']['newPassword'];
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(_errorMessage(e, 'Tạo mật khẩu thất bại'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  /// Get users/employees filtered by branch (for Store Manager)
  Future<List<User>> getUsersByBranch({required int branchId}) async {
    try {
      print("Đang gọi API: /Employees với branchId = $branchId");

      final response = await _dioClient.dio.get(
        '/Employees',
        queryParameters: {'branchId': branchId},
      );

      print("Dữ liệu phản hồi từ server: ${response.data}");

      // Xử lý dữ liệu linh hoạt (đề phòng backend trả về object bọc hoặc array trực tiếp)
      final dynamic rawData =
          (response.data is Map && response.data.containsKey('data'))
          ? response.data['data']
          : response.data;

      if (rawData == null || rawData is! List) {
        print("Cảnh báo: Dữ liệu không phải là danh sách hoặc bị null");
        return [];
      }

      return (rawData as List)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print("Dio Error khi gọi getUsersByBranch: ${e.message}");
      if (e.response != null && e.response?.data != null) {
        throw Exception(_errorMessage(e, 'Lỗi tải nhân viên chi nhánh'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    } catch (e) {
      print("Lỗi không xác định: $e");
      throw Exception('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      await _dioClient.dio.post(ApiConstants.users, data: data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(_errorMessage(e, 'Thêm người dùng thất bại'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    try {
      await _dioClient.dio.put('${ApiConstants.users}/$id', data: data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw Exception(_errorMessage(e, 'Cập nhật người dùng thất bại'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }

  Future<void> updateEmployee(int id, Map<String, dynamic> data) async {
    try {
      await _dioClient.dio.put('${ApiConstants.employees}/$id', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(_errorMessage(e, 'Cập nhật nhân viên thất bại'));
      }
      throw Exception('Không thể kết nối đến máy chủ.');
    }
  }
}
