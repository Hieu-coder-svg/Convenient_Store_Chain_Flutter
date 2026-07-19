import 'package:flutter/foundation.dart';
import '../models/shift.dart';
import '../models/attendance.dart';
import '../services/hr_service.dart';

class HrProvider extends ChangeNotifier {
  final HrService _hrService;

  HrProvider(this._hrService);

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;

  // Shifts
  List<ShiftModel> _shiftTemplates = [];
  List<ShiftAssignment> _storeSchedule = [];
  List<ShiftAssignment> _mySchedule = [];
  List<Map<String, dynamic>> _employees = [];

  // Attendance
  AttendanceRecord? _todayAttendance;
  final List<AttendanceRecord> _myRecentAttendance = [];
  List<AttendanceReportItem> _branchReport = [];
  List<AttendanceRecord> _attendanceHistory = [];
  List<ShiftAssignment> _attendanceAssignments = [];
  List<WorkHistoryItem> _workHistory = [];

  // Current week
  DateTime _weekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ShiftModel> get shiftTemplates => _shiftTemplates;
  List<ShiftAssignment> get storeSchedule => _storeSchedule;
  List<ShiftAssignment> get mySchedule => _mySchedule;
  List<Map<String, dynamic>> get employees => _employees;
  AttendanceRecord? get todayAttendance => _todayAttendance;
  List<AttendanceRecord> get myRecentAttendance => _myRecentAttendance;
  List<AttendanceReportItem> get branchReport => _branchReport;
  List<AttendanceRecord> get attendanceHistory => _attendanceHistory;
  List<ShiftAssignment> get attendanceAssignments => _attendanceAssignments;
  List<WorkHistoryItem> get workHistory => _workHistory;
  DateTime get weekStart => _weekStart;
  DateTime get weekEnd => _weekStart.add(const Duration(days: 6));

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSessionData() {
    _error = null;
    _isLoading = false;
    _shiftTemplates = [];
    _storeSchedule = [];
    _mySchedule = [];
    _employees = [];
    _todayAttendance = null;
    _branchReport = [];
    _attendanceHistory = [];
    _attendanceAssignments = [];
    _workHistory = [];
    final now = DateTime.now();
    _weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    notifyListeners();
  }

  // ── SHIFTS ────────────────────────────────────────────────────────────────

  Future<void> loadShiftTemplates(int branchId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _shiftTemplates = await _hrService.getShiftsByBranch(branchId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStoreSchedule(int branchId, {DateTime? weekStart}) async {
    if (weekStart != null) _weekStart = weekStart;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _storeSchedule = await _hrService.getStoreSchedule(
        branchId: branchId,
        startDate: _weekStart,
        endDate: _weekStart.add(const Duration(days: 6)),
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadScheduleBuilder(int branchId, {DateTime? weekStart}) async {
    if (weekStart != null) _weekStart = weekStart;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _shiftTemplates = await _hrService.getShiftsByBranch(branchId);
      _employees = await _hrService.getEmployeesByBranch(branchId);
      _storeSchedule = await _hrService.getStoreSchedule(
        branchId: branchId,
        startDate: _weekStart,
        endDate: _weekStart.add(const Duration(days: 6)),
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMySchedule({DateTime? weekStart}) async {
    if (weekStart != null) _weekStart = weekStart;
    final start = _weekStart;
    final end = start.add(const Duration(days: 6));
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mySchedule = await _hrService.getMySchedule(
        startDate: start,
        endDate: end,
      );
      _todayAttendance = await _hrService.getTodayAttendance();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createShiftTemplate({
    required int branchId,
    required String shiftName,
    required String startTime,
    required String endTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final newShift = await _hrService.createShift(
        branchId: branchId,
        shiftName: shiftName,
        startTime: startTime,
        endTime: endTime,
      );
      _shiftTemplates.add(newShift);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateShiftTemplate({
    required int shiftId,
    required String shiftName,
    required String startTime,
    required String endTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _hrService.updateShift(
        shiftId: shiftId,
        shiftName: shiftName,
        startTime: startTime,
        endTime: endTime,
      );
      final index = _shiftTemplates.indexWhere(
        (shift) => shift.shiftId == shiftId,
      );
      if (index >= 0) _shiftTemplates[index] = updated;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteShiftTemplate(int shiftId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _hrService.deleteShift(shiftId);
      _shiftTemplates.removeWhere((shift) => shift.shiftId == shiftId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignShift({
    required int employeeId,
    required int shiftId,
    required DateTime workDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final assignments = await _hrService.assignShift(
        employeeIds: [employeeId],
        shiftId: shiftId,
        startDate: workDate,
        endDate: workDate,
      );
      _storeSchedule.addAll(assignments);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAssignment({
    required int assignmentId,
    required int employeeId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _hrService.updateAssignment(
        assignmentId: assignmentId,
        employeeId: employeeId,
      );
      final index = _storeSchedule.indexWhere(
        (item) => item.assignmentId == assignmentId,
      );
      if (index >= 0) _storeSchedule[index] = updated;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAssignment(int assignmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _hrService.deleteAssignment(assignmentId);
      _storeSchedule.removeWhere((item) => item.assignmentId == assignmentId);
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── ATTENDANCE ────────────────────────────────────────────────────────────

  Future<bool> checkIn({
    required int shiftAssignmentId,
    required double latitude,
    required double longitude,
    String? wifiBssid,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _todayAttendance = await _hrService.checkIn(
        shiftAssignmentId: shiftAssignmentId,
        latitude: latitude,
        longitude: longitude,
        wifiBssid: wifiBssid,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkOut({
    required int attendanceId,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _todayAttendance = await _hrService.checkOut(
        attendanceId: attendanceId,
        latitude: latitude,
        longitude: longitude,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBranchReport({
    required int branchId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _branchReport = await _hrService.getAttendanceReport(
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAttendanceEmployees(int branchId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _employees = await _hrService.getEmployeesByBranch(branchId);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAttendanceHistory({
    required int branchId,
    required int employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _attendanceHistory = await _hrService.getAttendanceHistory(
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
      );
      final schedule = await _hrService.getStoreSchedule(
        branchId: branchId,
        startDate: startDate,
        endDate: endDate,
      );
      _attendanceAssignments = schedule
          .where((assignment) => assignment.employeeId == employeeId)
          .toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveManualAttendance({
    required int shiftAssignmentId,
    required DateTime checkInTime,
    DateTime? checkOutTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _hrService.saveManualAttendance(
        shiftAssignmentId: shiftAssignmentId,
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
      );
      _todayAttendance = saved;
      final index = _attendanceHistory.indexWhere(
        (record) => record.attendanceId == saved.attendanceId,
      );
      if (index >= 0) {
        _attendanceHistory[index] = saved;
      } else {
        _attendanceHistory.add(saved);
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkHistory({
    int? branchId,
    int? employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _workHistory = await _hrService.getWorkHistory(
        branchId: branchId,
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _workHistory = [];
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Group store schedule by date
  Map<String, List<ShiftAssignment>> get scheduleByDate {
    final Map<String, List<ShiftAssignment>> result = {};
    for (final a in _storeSchedule) {
      final key =
          '${a.workDate.year}-${a.workDate.month.toString().padLeft(2, '0')}-${a.workDate.day.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => []).add(a);
    }
    return result;
  }
}
