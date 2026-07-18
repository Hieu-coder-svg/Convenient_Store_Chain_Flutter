import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/customer_model.dart';

class CustomerApiService {
  final DioClient _dioClient;

  CustomerApiService(this._dioClient);

  Future<CustomerModel?> searchByPhone(String phone) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.customers}/search/phone/$phone',
      );
      if (response.data != null && response.data['data'] != null) {
        return CustomerModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<CustomerModel?> searchByMembership(String membershipId) async {
    try {
      final response = await _dioClient.dio.get(
        '${ApiConstants.customers}/search/membership/$membershipId',
      );
      if (response.data != null && response.data['data'] != null) {
        return CustomerModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<CustomerModel> createCustomer(String fullName, String phone) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.customers,
        data: {'fullName': fullName, 'phone': phone},
      );
      return CustomerModel.fromJson(response.data['data']);
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
