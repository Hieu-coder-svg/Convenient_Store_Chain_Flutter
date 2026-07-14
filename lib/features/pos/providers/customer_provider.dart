import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/customer_api_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerApiService _customerService;

  CustomerModel? _selectedCustomer;
  bool _isSearching = false;
  String? _error;

  CustomerProvider(this._customerService);

  CustomerModel? get selectedCustomer => _selectedCustomer;
  bool get isSearching => _isSearching;
  String? get error => _error;

  void setSelectedCustomer(CustomerModel customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  Future<CustomerModel?> searchByPhone(String phone) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final customer = await _customerService.searchByPhone(phone);
      _isSearching = false;
      notifyListeners();
      return customer;
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
      return null;
    }
  }

  Future<CustomerModel?> searchByMembership(String membershipId) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final customer = await _customerService.searchByMembership(membershipId);
      _isSearching = false;
      notifyListeners();
      return customer;
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
      return null;
    }
  }

  Future<CustomerModel?> registerCustomer(String fullName, String phone) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final customer = await _customerService.createCustomer(fullName, phone);
      _isSearching = false;
      notifyListeners();
      return customer;
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
      return null;
    }
  }
}
