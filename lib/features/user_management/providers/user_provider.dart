import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_stats.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService;

  UserProvider(this._userService);

  List<User> _users = [];
  UserStats? _stats;
  bool _isLoading = false;
  String? _error;
  
  // Pagination & Search state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String _searchTerm = '';

  List<User> get users => _users;
  UserStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  String get searchTerm => _searchTerm;

  void setSearchTerm(String term) {
    _searchTerm = term;
    fetchUsers(page: 1); // Reset to page 1 on new search
  }

  Future<void> fetchUsers({int? page}) async {
    if (page != null) {
      _currentPage = page;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pagedResult = await _userService.getUsers(
        pageNumber: _currentPage,
        searchTerm: _searchTerm,
      );
      _users = pagedResult.items;
      _totalCount = pagedResult.totalCount;
      _totalPages = pagedResult.totalPages;
      
      // Also fetch stats when we fetch users
      _stats = await _userService.getUserStats();
      
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activateUser(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.activateUser(id);
      // Update local state
      final index = _users.indexWhere((u) => u.userId == id);
      if (index != -1) {
        // Since User fields are final, we could recreate the user or just refetch
        await fetchUsers(); 
        return true;
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateUser(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.deactivateUser(id);
      await fetchUsers(); 
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> resetPassword(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPassword = await _userService.resetPassword(id);
      _isLoading = false;
      notifyListeners();
      return newPassword;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
