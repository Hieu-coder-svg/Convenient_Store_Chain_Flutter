import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Handle specific error message from the backend
        final message = e.response?.data['message'] ?? 'Đăng nhập thất bại';
        throw Exception(message);
      }
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định.');
    }
  }
}
