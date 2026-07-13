import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/cloudinary_constants.dart';

class CloudinaryService {
  static final Dio _dio = Dio();

  static Future<String> uploadImage(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File hình ảnh không tồn tại.');
      }

      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'upload_preset': CloudinaryConstants.uploadPreset,
      });

      final response = await _dio.post(
        CloudinaryConstants.uploadUrl,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final secureUrl = response.data['secure_url'];
        if (secureUrl != null) {
          return secureUrl as String;
        }
      }
      throw Exception('Không thể lấy URL hình ảnh từ Cloudinary.');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Lỗi Cloudinary: $errorMsg');
    } catch (e) {
      throw Exception('Lỗi tải ảnh lên: $e');
    }
  }
}
