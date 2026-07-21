import 'package:flutter/foundation.dart';
import '../models/purchase_order_model.dart';
import '../services/purchase_order_api_service.dart';

class PurchaseOrderProvider extends ChangeNotifier {
  final PurchaseOrderApiService _apiService;

  List<PurchaseOrderModel> _orders = [];
  List<PurchaseOrderModel> _pendingOrders = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String? _currentSearch;
  String? _currentStatus;

  PurchaseOrderProvider(this._apiService);

  List<PurchaseOrderModel> get orders => _orders;
  List<PurchaseOrderModel> get pendingOrders => _pendingOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  String? get currentSearch => _currentSearch;
  String? get currentStatus => _currentStatus;

  Future<void> fetchOrders({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getPurchaseOrders(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
      );
      _orders = result.items;
      _currentPage = result.pageNumber;
      _totalPages = result.totalPages > 0 ? result.totalPages : 1;
      _totalCount = result.totalCount;
      _currentSearch = search;
      _currentStatus = status;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPendingOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      const pageSize = 100;
      var page = 1;
      var totalPages = 1;
      final allOrders = <PurchaseOrderModel>[];
      do {
        final result = await _apiService.getPurchaseOrders(
          page: page,
          pageSize: pageSize,
          status: 'Pending',
        );
        allOrders.addAll(result.items);
        totalPages = result.totalPages > 0 ? result.totalPages : 1;
        page++;
      } while (page <= totalPages);
      _pendingOrders = allOrders;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PurchaseOrderModel?> fetchOrderById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final order = await _apiService.getPurchaseOrderById(id);
      final index = _orders.indexWhere((item) => item.poId == id);
      if (index >= 0) {
        _orders[index] = order;
      } else {
        _orders.add(order);
      }
      return order;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(
    int supplierId,
    List<Map<String, dynamic>> items,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestData = {'supplierId': supplierId, 'items': items};

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
