import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/reset_password_request.dart';

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

  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'] ?? 'Gửi yêu cầu thất bại';
        throw Exception(message);
      }
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định.');
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.resetPassword,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final message = e.response?.data['message'] ?? 'Đổi mật khẩu thất bại';
        throw Exception(message);
      }
      throw Exception('Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định.');
    }
  }
}
