import 'package:flutter/material.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationApiService _apiService;
  HubConnection? _hubConnection;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _totalCount = 0;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _totalCount;
  int get unreadCount => _unreadCount;

  NotificationProvider(this._apiService);

  Future<void> fetchNotifications({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getNotifications(page: page);
      final items = (data['items'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
      
      if (page == 1) {
        _notifications = items;
      } else {
        _notifications.addAll(items);
      }
      _totalCount = data['totalCount'];
      
      await fetchUnreadCount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    _unreadCount = await _apiService.getUnreadCount();
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    await _apiService.markAsRead(notificationId);
    
    // Update local state
    final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      // Create a copy with isRead = true (since fields are final)
      final n = _notifications[index];
      _notifications[index] = NotificationModel(
        notificationId: n.notificationId,
        userId: n.userId,
        title: n.title,
        message: n.message,
        isRead: true,
        createdAt: n.createdAt,
      );
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _apiService.markAllAsRead();
    
    // Update local state
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        final n = _notifications[i];
        _notifications[i] = NotificationModel(
          notificationId: n.notificationId,
          userId: n.userId,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  // SIGNALR Integration
  Future<void> startSignalR() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) return;

    // TODO: Change to real backend URL
    const serverUrl = "https://10.0.2.2:5001/hubs/inventory"; // 10.0.2.2 is local for Android emulator
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) => debugPrint("SignalR Connection Closed: $error"));
    
    _hubConnection?.on("ReceiveNotification", _handleNewNotification);

    try {
      await _hubConnection?.start();
      debugPrint("SignalR Connected Successfully");
    } catch (e) {
      debugPrint("SignalR Connection Error: $e");
    }
  }

  void _handleNewNotification(List<Object?>? parameters) {
    if (parameters != null && parameters.isNotEmpty) {
      debugPrint("New Realtime Notification: ${parameters[0]}");
      // Fetch latest unread count and first page
      fetchNotifications(page: 1);
    }
  }

  void stopSignalR() {
    _hubConnection?.stop();
  }
}
