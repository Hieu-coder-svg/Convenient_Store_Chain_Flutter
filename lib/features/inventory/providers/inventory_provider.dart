import 'package:flutter/material.dart';
import '../models/warehouse_inventory_model.dart';
import '../models/branch_inventory_model.dart';
import '../services/inventory_api_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryApiService _apiService;

  InventoryProvider(this._apiService);

  // Warehouse State
  List<WarehouseInventoryModel> _warehouseItems = [];
  bool _isLoadingWarehouse = false;
  String? _warehouseError;
  int _warehouseTotalCount = 0;

  List<WarehouseInventoryModel> get warehouseItems => _warehouseItems;
  bool get isLoadingWarehouse => _isLoadingWarehouse;
  String? get warehouseError => _warehouseError;
  int get warehouseTotalCount => _warehouseTotalCount;

  // Branch State
  List<BranchInventoryModel> _branchItems = [];
  bool _isLoadingBranch = false;
  String? _branchError;
  int _branchTotalCount = 0;

  List<BranchInventoryModel> get branchItems => _branchItems;
  bool get isLoadingBranch => _isLoadingBranch;
  String? get branchError => _branchError;
  int get branchTotalCount => _branchTotalCount;

  Future<void> fetchWarehouseInventory({int page = 1, String? search}) async {
    _isLoadingWarehouse = true;
    _warehouseError = null;
    notifyListeners();

    try {
      final data = await _apiService.getWarehouseInventory(
        page: page,
        search: search,
      );
      final items = (data['items'] as List)
          .map((item) => WarehouseInventoryModel.fromJson(item))
          .toList();

      if (page == 1) {
        _warehouseItems = items;
      } else {
        _warehouseItems.addAll(items);
      }
      _warehouseTotalCount = data['totalCount'];
    } catch (e) {
      _warehouseError = e.toString();
    } finally {
      _isLoadingWarehouse = false;
      notifyListeners();
    }
  }

  Future<void> fetchBranchInventory(
    int branchId, {
    int page = 1,
    String? search,
  }) async {
    _isLoadingBranch = true;
    _branchError = null;
    notifyListeners();

    try {
      final data = await _apiService.getBranchInventory(
        branchId,
        page: page,
        search: search,
      );
      final items = (data['items'] as List)
          .map((item) => BranchInventoryModel.fromJson(item))
          .toList();

      if (page == 1) {
        _branchItems = items;
      } else {
        _branchItems.addAll(items);
      }
      _branchTotalCount = data['totalCount'];
    } catch (e) {
      _branchError = e.toString();
    } finally {
      _isLoadingBranch = false;
      notifyListeners();
    }
  }

  Future<void> adjustStock(
    int branchId,
    List<Map<String, dynamic>> items,
  ) async {
    await _apiService.adjustStock(branchId, items);
    // Refresh branch inventory after adjustment
    await fetchBranchInventory(branchId);
  }

  Future<void> receiveGoods(Map<String, dynamic> request) async {
    await _apiService.receiveGoods(request);
    // Optionally refresh warehouse inventory
    await fetchWarehouseInventory();
  }
}
