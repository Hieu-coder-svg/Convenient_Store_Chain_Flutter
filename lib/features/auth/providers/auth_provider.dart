import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/reset_password_request.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _error;
  AuthResponse? _currentUser;

  AuthProvider(this._authService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  AuthResponse? get currentUser => _currentUser;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _authService.login(request);
      
      _currentUser = response;

      // Store tokens
      await _secureStorage.write(key: 'jwt_token', value: response.accessToken);
      await _secureStorage.write(key: 'refresh_token', value: response.refreshToken);

      _isLoading = false;
      notifyListeners();
      return true; // Success
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false; // Failure
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'refresh_token');
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> forgotPassword(String username, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(username, email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = ResetPasswordRequest(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      await _authService.resetPassword(request);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
