import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  final DioClient _dioClient;

  NotificationApiService(this._dioClient);

  Future<Map<String, dynamic>> getNotifications({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dioClient.dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi tải danh sách thông báo');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      return 0; // Silently fail
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dioClient.dio.put('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đánh dấu đã đọc');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dioClient.dio.put('/notifications/read-all');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đánh dấu tất cả đã đọc');
    }
  }
}
