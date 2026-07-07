import 'dart:io';

class ApiConstants {
  // Base URL for the backend
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5119/api';
    }
    return 'http://localhost:5119/api';
  }
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';

  // Timeout settings
  static const int connectTimeout = 5000; // 5 seconds
  static const int receiveTimeout = 5000; // 5 seconds
}
