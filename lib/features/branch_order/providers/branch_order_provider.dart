import 'package:flutter/material.dart';
import '../models/branch_order_model.dart';
import '../services/branch_order_api_service.dart';

class BranchOrderProvider extends ChangeNotifier {
  final BranchOrderApiService _apiService;

  BranchOrderProvider(this._apiService);

  List<BranchOrderModel> _orders = [];
  BranchOrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  List<BranchOrderModel> get orders => _orders;
  BranchOrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders({int? branchId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _apiService.getOrders(branchId: branchId, status: status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrderDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await _apiService.getOrderById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(
    int branchId,
    List<Map<String, dynamic>> items,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.createOrder(branchId, items);
      // Automatically refresh the list
      await fetchOrders();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveOrder(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.approveOrder(id);
      await fetchOrderDetail(id); // Reload the detail
      await fetchOrders(); // Reload the list
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmReceived(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.confirmReceived(id);
      await fetchOrderDetail(id); // Reload the detail
      await fetchOrders(); // Reload the list
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.cancelOrder(id);
      await fetchOrderDetail(id); // Reload the detail
      await fetchOrders(); // Reload the list
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
