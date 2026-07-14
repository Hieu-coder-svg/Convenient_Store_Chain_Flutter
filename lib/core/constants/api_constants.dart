import 'dart:io';

class ApiConstants {
  // Base URL for the backend
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // User endpoints
  static const String users = '/user';

  // Branch Order endpoints (Task 4.1)
  static const String branchOrders = '/BranchOrder';

  // Invoice endpoints (Task 4.2)
  static const String invoices = '/Invoice';

  // Customer endpoints (Task 4.2 - Loyalty)
  static const String customers = '/Customer';
  // Timeout settings
  static const int connectTimeout = 5000; // 5 seconds
  static const int receiveTimeout = 5000; // 5 seconds
}
