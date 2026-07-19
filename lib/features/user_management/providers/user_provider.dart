import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_stats.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService;

  UserProvider(this._userService);

  // Trạng thái hiện tại
  List<User> _users = [];
  UserStats? _stats;
  bool _isLoading = false;
  String? _error;

  // Pagination & Search state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String _searchTerm = '';

  // Lưu mode hiện tại để reload đúng danh sách sau khi thao tác
  int? _forcedBranchId;

  // Getters
  List<User> get users => _users;
  UserStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  String get searchTerm => _searchTerm;
  bool get isFilteringByBranch => _forcedBranchId != null;

  void setSearchTerm(String term) {
    _searchTerm = term;
    loadUsers(branchId: _forcedBranchId, page: 1);
  }

  Future<void> loadUsers({
    int? branchId,
    int? page,
    bool requireBranch = false,
  }) async {
    if (requireBranch && (branchId == null || branchId <= 0)) {
      _users = [];
      _stats = null;
      _error = 'Tài khoản Manager chưa được gán chi nhánh.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _forcedBranchId = branchId != null && branchId > 0 ? branchId : null;

    if (page != null) {
      _currentPage = page;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_forcedBranchId != null) {
        _users = await _userService.getUsersByBranch(
          branchId: _forcedBranchId!,
        );

        _totalCount = _users.length;
        _totalPages = 1;
        _stats = UserStats(
          totalUsers: _users.length,
          storeManagers: _users
              .where((user) => user.roleName.contains('Manager'))
              .length,
          activeUsers: _users.where((user) => user.isActive).length,
          leaveRequests: 0,
        );
      } else {
        final pagedResult = await _userService.getUsers(
          pageNumber: _currentPage,
          searchTerm: _searchTerm,
        );

        _users = pagedResult.items;
        _totalCount = pagedResult.totalCount;
        _totalPages = pagedResult.totalPages;
        _stats = await _userService.getUserStats();
      }
    } catch (e, stackTrace) {
      debugPrint('Load users error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _userService.createUser(data);
      await loadUsers(
        branchId: _forcedBranchId,
      ); // Tự động reload đúng danh sách
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_forcedBranchId != null) {
        await _userService.updateEmployee(id, data);
      } else {
        await _userService.updateUser(id, data);
      }
      await loadUsers(
        branchId: _forcedBranchId,
      ); // Tự động reload đúng danh sách
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateUser(int id) async {
    try {
      await _userService.activateUser(id);
      await loadUsers(branchId: _forcedBranchId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateUser(int id) async {
    try {
      await _userService.deactivateUser(id);
      await loadUsers(branchId: _forcedBranchId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _userService.deleteUser(id);
      await loadUsers(branchId: _forcedBranchId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<String?> resetPassword(int id) async {
    try {
      return await _userService.resetPassword(id);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
