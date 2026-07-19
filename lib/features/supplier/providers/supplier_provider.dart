import 'package:flutter/foundation.dart';
import '../models/supplier_model.dart';
import '../services/supplier_api_service.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierApiService _apiService;

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _error;
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  SupplierProvider(this._apiService);

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;

  Future<void> fetchSuppliers({int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pagedResult = await _apiService.getSuppliers(
        page: page,
        pageSize: 10,
      );
      
      _suppliers = pagedResult.items;
      _currentPage = pagedResult.pageNumber;
      _totalCount = pagedResult.totalCount;
      _totalPages = (pagedResult.totalCount / 10).ceil();
      if (_totalPages == 0) _totalPages = 1;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(SupplierModel supplier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _apiService.createSupplier(supplier);
      _suppliers.add(created);
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

  Future<bool> editSupplier(SupplierModel supplier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.updateSupplier(supplier);
      if (success) {
        final index = _suppliers.indexWhere(
          (s) => s.supplierId == supplier.supplierId,
        );
        if (index != -1) {
          _suppliers[index] = supplier;
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

  Future<bool> removeSupplier(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _apiService.deleteSupplier(id);
      if (success) {
        _suppliers.removeWhere((s) => s.supplierId == id);
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
