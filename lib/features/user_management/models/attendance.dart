class AttendanceRecord {
  final int attendanceId;
  final int shiftAssignmentId;
  final int employeeId;
  final String? employeeName;
  final String? shiftName;
  final DateTime workDate;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInStatus;
  final String? checkOutStatus;
  final int lateMinutes;
  final int earlyMinutes;

  AttendanceRecord({
    required this.attendanceId,
    required this.shiftAssignmentId,
    required this.employeeId,
    this.employeeName,
    this.shiftName,
    required this.workDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInStatus,
    this.checkOutStatus,
    required this.lateMinutes,
    required this.earlyMinutes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      attendanceId: json['attendanceId'] ?? 0,
      shiftAssignmentId: json['shiftAssignmentId'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'],
      shiftName: json['shiftName'],
      workDate: json['workDate'] != null
          ? DateTime.parse(json['workDate'])
          : DateTime.now(),
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      checkInStatus: json['checkInStatus'],
      checkOutStatus: json['checkOutStatus'],
      lateMinutes: json['lateMinutes'] ?? 0,
      earlyMinutes: json['earlyMinutes'] ?? 0,
    );
  }

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
  bool get isOnTime => lateMinutes == 0;
}

class AttendanceReportItem {
  final int employeeId;
  final String employeeName;
  final int totalShifts;
  final int totalPresent;
  final int totalLate;
  final int totalEarlyLeave;
  final int totalAbsent;
  final int totalLateMinutes;
  final int totalEarlyMinutes;

  AttendanceReportItem({
    required this.employeeId,
    required this.employeeName,
    required this.totalShifts,
    required this.totalPresent,
    required this.totalLate,
    required this.totalEarlyLeave,
    required this.totalAbsent,
    required this.totalLateMinutes,
    required this.totalEarlyMinutes,
  });

  factory AttendanceReportItem.fromJson(Map<String, dynamic> json) {
    return AttendanceReportItem(
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? '',
      totalShifts: json['totalShifts'] ?? 0,
      totalPresent: json['totalPresent'] ?? 0,
      totalLate: json['totalLate'] ?? 0,
      totalEarlyLeave: json['totalEarlyLeave'] ?? 0,
      totalAbsent: json['totalAbsent'] ?? 0,
      totalLateMinutes: json['totalLateMinutes'] ?? 0,
      totalEarlyMinutes: json['totalEarlyMinutes'] ?? 0,
    );
  }

  String get attendanceRate =>
      totalShifts > 0 ? '$totalPresent/$totalShifts ngày' : '-';
}

class WorkHistoryItem {
  final int attendanceId;
  final int shiftAssignmentId;
  final int employeeId;
  final String employeeName;
  final String shiftName;
  final DateTime workDate;
  final String scheduledStartTime;
  final String scheduledEndTime;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final int lateMinutes;
  final int earlyMinutes;
  final String workStatus;

  const WorkHistoryItem({
    required this.attendanceId,
    required this.shiftAssignmentId,
    required this.employeeId,
    required this.employeeName,
    required this.shiftName,
    required this.workDate,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    this.checkInTime,
    this.checkOutTime,
    required this.lateMinutes,
    required this.earlyMinutes,
    required this.workStatus,
  });

  factory WorkHistoryItem.fromJson(Map<String, dynamic> json) {
    return WorkHistoryItem(
      attendanceId: json['attendanceId'] ?? 0,
      shiftAssignmentId: json['shiftAssignmentId'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'] ?? 'Nhân viên',
      shiftName: json['shiftName'] ?? 'Ca làm việc',
      workDate: DateTime.parse(json['workDate']),
      scheduledStartTime: json['scheduledStartTime'] ?? '00:00:00',
      scheduledEndTime: json['scheduledEndTime'] ?? '00:00:00',
      checkInTime: json['checkInTime'] == null
          ? null
          : DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] == null
          ? null
          : DateTime.parse(json['checkOutTime']),
      lateMinutes: json['lateMinutes'] ?? 0,
      earlyMinutes: json['earlyMinutes'] ?? 0,
      workStatus: json['workStatus'] ?? 'Upcoming',
    );
  }

  bool get isAbsent => workStatus == 'Absent';
  bool get isLate => workStatus.contains('Late');
  bool get isEarlyLeave => workStatus.contains('EarlyLeave');
  bool get isWorking => workStatus == 'Working' || workStatus == 'LateWorking';
}
