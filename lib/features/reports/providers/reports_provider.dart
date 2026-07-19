import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../models/chain_revenue_dto.dart';
import '../models/branch_performance_dto.dart';
import '../models/top_selling_product_dto.dart';
import '../models/supplier_performance_dto.dart';
import '../models/low_stock_alert_dto.dart';

class ReportsProvider with ChangeNotifier {
  final DioClient _dioClient;

  ReportsProvider(this._dioClient);

  bool _isLoadingRevenue = false;
  bool get isLoadingRevenue => _isLoadingRevenue;

  bool _isLoadingBranchPerformance = false;
  bool get isLoadingBranchPerformance => _isLoadingBranchPerformance;

  bool _isLoadingTopProducts = false;
  bool get isLoadingTopProducts => _isLoadingTopProducts;

  bool _isLoadingSupplierPerformance = false;
  bool get isLoadingSupplierPerformance => _isLoadingSupplierPerformance;

  bool _isLoadingAlerts = false;
  bool get isLoadingAlerts => _isLoadingAlerts;

  ChainRevenueDto? _chainRevenue;
  ChainRevenueDto? get chainRevenue => _chainRevenue;

  List<BranchPerformanceDto> _branchPerformanceList = [];
  List<BranchPerformanceDto> get branchPerformanceList => _branchPerformanceList;

  List<TopSellingProductDto> _topProducts = [];
  List<TopSellingProductDto> get topProducts => _topProducts;

  List<SupplierPerformanceDto> _supplierPerformanceList = [];
  List<SupplierPerformanceDto> get supplierPerformanceList => _supplierPerformanceList;

  List<LowStockAlertDto>? _lowStockAlerts;
  List<LowStockAlertDto>? get lowStockAlerts => _lowStockAlerts;

  String? _error;
  String? get error => _error;

  Future<void> fetchChainRevenue(DateTime startDate, DateTime endDate, {String interval = 'daily'}) async {
    _isLoadingRevenue = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/Reports/chain-revenue', queryParameters: {
        'startDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(startDate),
        'endDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(endDate),
        'interval': interval,
      });

      _chainRevenue = ChainRevenueDto.fromJson(response.data);
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message ?? 'An error occurred';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingRevenue = false;
      notifyListeners();
    }
  }

  Future<void> fetchBranchPerformance(DateTime startDate, DateTime endDate) async {
    _isLoadingBranchPerformance = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/Reports/branch-performance', queryParameters: {
        'startDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(startDate),
        'endDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(endDate),
      });

      var list = response.data as List? ?? [];
      _branchPerformanceList = list.map((i) => BranchPerformanceDto.fromJson(i)).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message ?? 'An error occurred';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingBranchPerformance = false;
      notifyListeners();
    }
  }

  Future<void> fetchTopProducts(DateTime startDate, DateTime endDate, {int top = 10}) async {
    _isLoadingTopProducts = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/Reports/top-products', queryParameters: {
        'startDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(startDate),
        'endDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(endDate),
        'top': top,
      });

      var list = response.data as List? ?? [];
      _topProducts = list.map((i) => TopSellingProductDto.fromJson(i)).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message ?? 'An error occurred';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingTopProducts = false;
      notifyListeners();
    }
  }

  Future<void> fetchSupplierPerformance(DateTime startDate, DateTime endDate) async {
    _isLoadingSupplierPerformance = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/Reports/supplier-performance', queryParameters: {
        'startDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(startDate),
        'endDate': DateFormat('yyyy-MM-ddTHH:mm:ss').format(endDate),
      });

      var list = response.data as List? ?? [];
      _supplierPerformanceList = list.map((i) => SupplierPerformanceDto.fromJson(i)).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? e.message ?? 'An error occurred';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingSupplierPerformance = false;
      notifyListeners();
    }
  }

  Future<void> fetchLowStockAlerts() async {
    _isLoadingAlerts = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioClient.dio.get(
        '/Reports/low-stock-alerts',
      );

      final List<dynamic> data = response.data;
      _lowStockAlerts = data.map((json) => LowStockAlertDto.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
      _lowStockAlerts = null;
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }
}
