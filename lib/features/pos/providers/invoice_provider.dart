import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
import '../models/daily_summary_model.dart';
import '../models/period_summary_model.dart';
import '../services/invoice_api_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceApiService _invoiceService;

  bool _isLoading = false;
  String? _error;
  InvoiceModel? _lastCreatedInvoice;

  InvoiceProvider(this._invoiceService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  InvoiceModel? get lastCreatedInvoice => _lastCreatedInvoice;

  Future<bool> checkout(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final invoice = await _invoiceService.createInvoice(data);
      _lastCreatedInvoice = invoice;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<InvoiceModel?> getInvoiceById(int id) async {
    // If it's already the last created invoice, just return it
    if (_lastCreatedInvoice?.invoiceId == id) {
      return _lastCreatedInvoice;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final invoice = await _invoiceService.getInvoiceById(id);
      _isLoading = false;
      notifyListeners();
      return invoice;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  List<InvoiceModel> _invoices = [];
  List<InvoiceModel> get invoices => _invoices;

  Future<void> fetchInvoices({int? branchId, DateTime? fromDate, DateTime? toDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String? fromStr = fromDate?.toIso8601String().split('T')[0];
      final String? toStr = toDate?.toIso8601String().split('T')[0];

      _invoices = await _invoiceService.getInvoices(
        branchId: branchId,
        fromDate: fromStr,
        toDate: toStr,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DailySummaryModel?> fetchDailySummary({required int branchId, required DateTime date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String dateStr = date.toIso8601String().split('T')[0];
      final Map<String, dynamic> data = await _invoiceService.getDailySummary(branchId, dateStr);
      final summary = DailySummaryModel.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return summary;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<PeriodSummaryModel?> fetchPeriodSummary({required int branchId, required DateTime startDate, required DateTime endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String startDateStr = startDate.toIso8601String().split('T')[0];
      final String endDateStr = endDate.toIso8601String().split('T')[0];
      final Map<String, dynamic> data = await _invoiceService.getPeriodSummary(branchId, startDateStr, endDateStr);
      final summary = PeriodSummaryModel.fromJson(data);
      _isLoading = false;
      notifyListeners();
      return summary;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
