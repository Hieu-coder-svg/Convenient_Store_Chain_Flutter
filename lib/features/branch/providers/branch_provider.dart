import 'package:flutter/foundation.dart';
import '../models/branch_model.dart';
import '../services/branch_api_service.dart';

class BranchProvider extends ChangeNotifier {
  final BranchApiService _apiService;

  List<BranchModel> _branches = [];
  bool _isLoading = false;
  String? _error;

  BranchProvider(this._apiService);

  List<BranchModel> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBranches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _apiService.getBranches();
      _branches = list;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBranch(BranchModel branch) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.createBranch(branch);
      _branches.add(created);
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

  Future<bool> editBranch(BranchModel branch) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.updateBranch(branch);
      if (success) {
        final index = _branches.indexWhere(
          (b) => b.branchId == branch.branchId,
        );
        if (index != -1) {
          _branches[index] = branch;
        }
      }
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

  Future<bool> removeBranch(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteBranch(id);
      if (success) {
        _branches.removeWhere((b) => b.branchId == id);
      }
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
