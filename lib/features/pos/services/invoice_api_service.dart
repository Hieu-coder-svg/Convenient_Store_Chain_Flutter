import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/invoice_model.dart';

class InvoiceApiService {
  final DioClient _dioClient;

  InvoiceApiService(this._dioClient);

  Future<InvoiceModel> createInvoice(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.invoices,
        data: data,
      );
      if (response.data != null && response.data['data'] != null) {
        return InvoiceModel.fromJson(response.data['data']);
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<InvoiceModel> getInvoiceById(int id) async {
    try {
      final response = await _dioClient.dio.get('${ApiConstants.invoices}/$id');
      if (response.data != null && response.data['data'] != null) {
        return InvoiceModel.fromJson(response.data['data']);
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<List<InvoiceModel>> getInvoices({
    int? branchId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (branchId != null) queryParams['branchId'] = branchId;
      if (fromDate != null) queryParams['fromDate'] = fromDate;
      if (toDate != null) queryParams['toDate'] = toDate;

      final response = await _dioClient.dio.get(
        ApiConstants.invoices,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> list = response.data['data'];
        return list.map((e) => InvoiceModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> getDailySummary(
    int branchId,
    String date,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.invoices}/summary/daily',
        queryParameters: {'branchId': branchId, 'date': date},
      );
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> getPeriodSummary(
    int branchId,
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.invoices}/summary/period',
        queryParameters: {
          'branchId': branchId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'];
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final message = data is Map
          ? data['message']
          : 'Error: ${e.response?.statusCode}';
      return Exception(message ?? 'Unknown server error');
    } else {
      return Exception('Network error or server unreachable');
    }
  }
}
