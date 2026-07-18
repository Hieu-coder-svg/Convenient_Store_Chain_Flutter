class ShiftModel {
  final int shiftId;
  final int branchId;
  final String? branchName;
  final String shiftName;
  final String startTime;
  final String endTime;

  ShiftModel({
    required this.shiftId,
    required this.branchId,
    this.branchName,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      shiftId: json['shiftId'] ?? 0,
      branchId: json['branchId'] ?? 0,
      branchName: json['branchName'],
      shiftName: json['shiftName'] ?? '',
      startTime: json['startTime'] ?? '00:00:00',
      endTime: json['endTime'] ?? '00:00:00',
    );
  }

  String get displayTime {
    final start = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final end = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$start - $end';
  }
}

class ShiftAssignment {
  final int assignmentId;
  final int employeeId;
  final String? employeeName;
  final int shiftId;
  final String? shiftName;
  final DateTime workDate;
  final String status;
  final String startTime;
  final String endTime;

  ShiftAssignment({
    required this.assignmentId,
    required this.employeeId,
    this.employeeName,
    required this.shiftId,
    this.shiftName,
    required this.workDate,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) {
    return ShiftAssignment(
      assignmentId: json['assignmentId'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName'],
      shiftId: json['shiftId'] ?? 0,
      shiftName: json['shiftName'],
      workDate: json['workDate'] != null
          ? DateTime.parse(json['workDate'])
          : DateTime.now(),
      status: json['status'] ?? '',
      startTime: json['startTime'] ?? '00:00:00',
      endTime: json['endTime'] ?? '00:00:00',
    );
  }

  String get displayTime {
    final start = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final end = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$start - $end';
  }
}
