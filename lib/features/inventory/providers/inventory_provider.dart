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
  List<BranchInventoryModel> _adjustmentBranchItems = [];
  bool _isLoadingAdjustmentItems = false;

  List<BranchInventoryModel> get branchItems => _branchItems;
  bool get isLoadingBranch => _isLoadingBranch;
  String? get branchError => _branchError;
  int get branchTotalCount => _branchTotalCount;
  List<BranchInventoryModel> get adjustmentBranchItems =>
      _adjustmentBranchItems;
  bool get isLoadingAdjustmentItems => _isLoadingAdjustmentItems;

  Future<void> fetchWarehouseInventory({
    int page = 1,
    String? search,
    bool lowStockOnly = false,
  }) async {
    _isLoadingWarehouse = true;
    _warehouseError = null;
    notifyListeners();

    try {
      final data = await _apiService.getWarehouseInventory(
        page: page,
        pageSize: 10,
        search: search,
        lowStockOnly: lowStockOnly,
      );
      final items = (data['items'] as List)
          .map((item) => WarehouseInventoryModel.fromJson(item))
          .toList();

      _warehouseItems = items;
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
        pageSize: 10,
        search: search,
      );
      final items = (data['items'] as List)
          .map((item) => BranchInventoryModel.fromJson(item))
          .toList();

      _branchItems = items;
      _branchTotalCount = data['totalCount'];
    } catch (e) {
      _branchError = e.toString();
    } finally {
      _isLoadingBranch = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllBranchInventoryForAdjustment(int branchId) async {
    _isLoadingAdjustmentItems = true;
    _branchError = null;
    notifyListeners();
    try {
      const pageSize = 100;
      var page = 1;
      var totalCount = 0;
      final allItems = <BranchInventoryModel>[];
      do {
        final data = await _apiService.getBranchInventory(
          branchId,
          page: page,
          pageSize: pageSize,
        );
        final pageItems = (data['items'] as List)
            .map((item) => BranchInventoryModel.fromJson(item))
            .toList();
        allItems.addAll(pageItems);
        totalCount = data['totalCount'] as int? ?? allItems.length;
        page++;
      } while (allItems.length < totalCount);
      _adjustmentBranchItems = allItems;
    } catch (e) {
      _branchError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingAdjustmentItems = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> adjustStock(
    int branchId,
    List<Map<String, dynamic>> items,
  ) async {
    final result = await _apiService.adjustStock(branchId, items);
    // Refresh branch inventory after adjustment
    await fetchBranchInventory(branchId);
    await fetchAllBranchInventoryForAdjustment(branchId);
    return result;
  }

  Future<Map<String, dynamic>> receiveGoods(
    Map<String, dynamic> request,
  ) async {
    final result = await _apiService.receiveGoods(request);
    await fetchWarehouseInventory();
    return result;
  }
}
