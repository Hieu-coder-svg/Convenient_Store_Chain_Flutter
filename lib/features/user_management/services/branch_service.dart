import 'package:dio/dio.dart';
import '../models/branch.dart';

class BranchService {
  final Dio _dio;
  BranchService(this._dio);

  Future<List<Branch>> getAllBranches() async {
    // Thay '/branches' bằng đường dẫn đầy đủ nếu cần thiết
    final response = await _dio.get('/api/branches');
    if (response.statusCode == 200) {
      return (response.data as List).map((i) => Branch.fromJson(i)).toList();
    }
    throw Exception('Không thể tải danh sách chi nhánh');
  }
}