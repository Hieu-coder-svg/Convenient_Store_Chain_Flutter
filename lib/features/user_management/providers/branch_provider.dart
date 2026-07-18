import 'package:flutter/material.dart';
import '../models/branch.dart';
import '../services/branch_service.dart';

class BranchProvider extends ChangeNotifier {
  final BranchService _branchService;
  List<Branch> _branches = [];
  bool _isLoading = false;

  BranchProvider(this._branchService);

  List<Branch> get branches => _branches;
  bool get isLoading => _isLoading;

  Future<void> fetchBranches() async {
    _isLoading = true;
    notifyListeners();
    try {
      _branches = await _branchService.getAllBranches();
    } catch (e) {
      debugPrint("Lỗi khi tải chi nhánh: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}