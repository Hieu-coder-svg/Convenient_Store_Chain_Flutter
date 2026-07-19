import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/shift.dart';
import '../models/attendance.dart';

class HrService {
  final DioClient _dioClient;

  HrService(this._dioClient);

  bool _isActiveAssignment(ShiftAssignment assignment) {
    final status = assignment.status.replaceAll(' ', '').toLowerCase();
    return status != 'cancelled' && status != 'canceled';
  }

  List<dynamic> _listData(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : responseData;
    if (data == null) return [];
    if (data is List) return data;
    throw const FormatException('Dữ liệu phản hồi không phải là danh sách');
  }

  Map<String, dynamic> _objectData(dynamic responseData) {
    final data = responseData is Map && responseData.containsKey('data')
        ? responseData['data']
        : responseData;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Dữ liệu phản hồi không phải là đối tượng');
  }

  String _errorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['Message'] ?? data['title'];
      if (message is String && message.trim().isNotEmpty) return message;
      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String && value.trim().isNotEmpty) return value;
        }
      }
    }
    if (data is String && data.trim().isNotEmpty) return data;
    if (error.response?.statusCode == 403) {
      return 'Bạn không có quyền thực hiện thao tác này tại chi nhánh hiện tại.';
    }
    if (error.response?.statusCode == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối và thử lại.';
    }
    return fallback;
  }

  // ── EMPLOYEES ────────────────────────────────────────────────────────────

  /// Get employees by branch (Store Manager sees only their branch)
  Future<List<Map<String, dynamic>>> getEmployeesByBranch(int branchId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.employees,
        queryParameters: {'branchId': branchId},
      );
      final data = _listData(response.data);
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải danh sách nhân viên'));
    }
  }

  // ── SHIFTS ────────────────────────────────────────────────────────────────

  /// Get shift templates for a branch
  Future<List<ShiftModel>> getShiftsByBranch(int branchId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.shifts,
        queryParameters: {'branchId': branchId},
      );
      final data = _listData(response.data);
      return data
          .map((e) => ShiftModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải ca làm việc'));
    }
  }

  /// Get store schedule (Manager view)
  Future<List<ShiftAssignment>> getStoreSchedule({
    required int branchId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.storeSchedule,
        queryParameters: {
          'branchId': branchId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      final data = _listData(response.data);
      return data
          .map(
            (e) =>
                ShiftAssignment.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .where(_isActiveAssignment)
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải lịch cửa hàng'));
    }
  }

  /// Get personal schedule (Staff view)
  Future<List<ShiftAssignment>> getMySchedule({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.mySchedule,
        queryParameters: {
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );
      final data = _listData(response.data);
      return data
          .map(
            (e) =>
                ShiftAssignment.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .where(_isActiveAssignment)
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải lịch cá nhân'));
    }
  }

  /// Create a shift template
  Future<ShiftModel> createShift({
    required int branchId,
    required String shiftName,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.shifts,
        data: {
          'branchId': branchId,
          'shiftName': shiftName,
          'startTime': startTime,
          'endTime': endTime,
        },
      );
      final data = _objectData(response.data);
      return ShiftModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tạo ca làm việc'));
    }
  }

  Future<ShiftModel> updateShift({
    required int shiftId,
    required String shiftName,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.shifts}/$shiftId',
        data: {
          'shiftName': shiftName,
          'startTime': startTime,
          'endTime': endTime,
        },
      );
      return ShiftModel.fromJson(_objectData(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể cập nhật ca làm việc'));
    }
  }

  Future<void> deleteShift(int shiftId) async {
    try {
      await _dioClient.dio.delete('${ApiConstants.shifts}/$shiftId');
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể xóa ca làm việc'));
    }
  }

  Future<List<ShiftAssignment>> assignShift({
    required List<int> employeeIds,
    required int shiftId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.shiftAssign,
        data: {
          'employeeIds': employeeIds,
          'shiftId': shiftId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return _listData(response.data)
          .map(
            (e) =>
                ShiftAssignment.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể phân ca làm việc'));
    }
  }

  Future<ShiftAssignment> updateAssignment({
    required int assignmentId,
    required int employeeId,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        '${ApiConstants.shifts}/assignments/$assignmentId',
        data: {'employeeId': employeeId},
      );
      return ShiftAssignment.fromJson(_objectData(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể đổi nhân viên'));
    }
  }

  Future<void> deleteAssignment(int assignmentId) async {
    try {
      await _dioClient.dio.delete(
        '${ApiConstants.shifts}/assignments/$assignmentId',
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể xóa nhân viên khỏi ca'));
    }
  }

  // ── ATTENDANCE ────────────────────────────────────────────────────────────

  /// Check-in
  Future<AttendanceRecord> checkIn({
    required int shiftAssignmentId,
    required double latitude,
    required double longitude,
    String? wifiBssid,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.attendanceCheckIn,
        data: {
          'shiftAssignmentId': shiftAssignmentId,
          'latitude': latitude,
          'longitude': longitude,
          'wifiBssid': ?wifiBssid,
        },
      );
      final data = _objectData(response.data);
      return AttendanceRecord.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Chấm công vào ca thất bại'));
    }
  }

  /// Check-out
  Future<AttendanceRecord> checkOut({
    required int attendanceId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.attendanceCheckOut,
        data: {
          'attendanceId': attendanceId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final data = _objectData(response.data);
      return AttendanceRecord.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Chấm công tan ca thất bại'));
    }
  }

  Future<AttendanceRecord?> getTodayAttendance() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.attendanceToday);
      if (response.statusCode == 204 || response.data == null) return null;
      return AttendanceRecord.fromJson(_objectData(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(
        _errorMessage(e, 'Không thể tải trạng thái chấm công hôm nay'),
      );
    }
  }

  /// Get attendance report for a branch
  Future<List<AttendanceReportItem>> getAttendanceReport({
    required int branchId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.attendanceReport,
        queryParameters: {
          'branchId': branchId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      final data = _listData(response.data);
      return data
          .map(
            (e) => AttendanceReportItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải báo cáo chấm công'));
    }
  }

  Future<List<AttendanceRecord>> getAttendanceHistory({
    required int employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.attendanceHistory,
        queryParameters: {
          'employeeId': employeeId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return _listData(response.data)
          .map(
            (e) =>
                AttendanceRecord.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải lịch sử chấm công'));
    }
  }

  Future<List<WorkHistoryItem>> getWorkHistory({
    int? branchId,
    int? employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.workHistory,
        queryParameters: {
          'branchId': ?branchId,
          'employeeId': ?employeeId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
      );
      return _listData(response.data)
          .map(
            (item) => WorkHistoryItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể tải lịch sử làm việc'));
    }
  }

  Future<AttendanceRecord> saveManualAttendance({
    required int shiftAssignmentId,
    required DateTime checkInTime,
    DateTime? checkOutTime,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/Attendances/manual',
        data: {
          'shiftAssignmentId': shiftAssignmentId,
          'checkInTime': checkInTime.toIso8601String(),
          'checkOutTime': checkOutTime?.toIso8601String(),
        },
      );
      return AttendanceRecord.fromJson(_objectData(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không thể lưu chấm công'));
    }
  }
}
