import 'dart:io';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  // Base URL for the backend
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (Platform.isAndroid) {
      // Android connects to the Docker API through `adb reverse tcp:8080
      // tcp:8080`. This works for both a USB device and an emulator.
      return 'http://127.0.0.1:8080/api';
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

  // Employee endpoints
  static const String employees = '/Employees';

  // Shift endpoints
  static const String shifts = '/Shifts';
  static const String shiftAssign = '/Shifts/assign';
  static const String storeSchedule = '/Shifts/store-schedule';
  static const String mySchedule = '/Shifts/my-schedule';

  // Attendance endpoints
  static const String attendanceCheckIn = '/Attendances/check-in';
  static const String attendanceCheckOut = '/Attendances/check-out';
  static const String attendanceToday = '/Attendances/my-today';
  static const String attendanceReport = '/Attendances/report';
  static const String attendanceHistory = '/Attendances/history';

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
