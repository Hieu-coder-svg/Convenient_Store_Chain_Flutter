import 'package:flutter/foundation.dart';
import '../models/invoice_model.dart';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
