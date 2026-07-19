import 'package:flutter/foundation.dart';
import '../models/purchase_order_model.dart';
import '../services/purchase_order_api_service.dart';

class PurchaseOrderProvider extends ChangeNotifier {
  final PurchaseOrderApiService _apiService;

  List<PurchaseOrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  PurchaseOrderProvider(this._apiService);

  List<PurchaseOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _apiService.getAllPurchaseOrders();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(int supplierId, List<Map<String, dynamic>> items) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestData = {
        'supplierId': supplierId,
        'items': items,
      };
      
      final newOrder = await _apiService.createPurchaseOrder(requestData);
      _orders.insert(0, newOrder);
      
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
