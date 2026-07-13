import 'package:flutter/foundation.dart';
import '../models/supplier_model.dart';
import '../services/supplier_api_service.dart';

class SupplierProvider extends ChangeNotifier {
  final SupplierApiService _apiService;

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _error;

  SupplierProvider(this._apiService);

  List<SupplierModel> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSuppliers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _apiService.getSuppliers();
      _suppliers = list;
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
        final index = _suppliers.indexWhere((s) => s.supplierId == supplier.supplierId);
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
