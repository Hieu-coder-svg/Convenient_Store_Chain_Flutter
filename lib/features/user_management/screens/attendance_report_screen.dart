import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance.dart';
import '../models/shift.dart';
import '../providers/hr_provider.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selectedEmployeeId;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  DateTime get _monthStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _monthEnd =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEmployees());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    final branchId = context.read<AuthProvider>().currentUser?.branchId;
    if (branchId == null) return;
    final provider = context.read<HrProvider>();
    await provider.loadAttendanceEmployees(branchId);
    if (mounted) setState(() {});
  }

  Future<void> _loadHistory() async {
    final employeeId = _selectedEmployeeId;
    final branchId = context.read<AuthProvider>().currentUser?.branchId;
    if (employeeId == null || branchId == null) return;
    await context.read<HrProvider>().loadAttendanceHistory(
      branchId: branchId,
      employeeId: employeeId,
      startDate: _monthStart,
      endDate: _monthEnd,
    );
  }

  Future<void> _showManualAttendanceDialog() async {
    final provider = context.read<HrProvider>();
    if (provider.attendanceAssignments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhân viên chưa được phân ca trong tháng này.'),
        ),
      );
      return;
    }

    ShiftAssignment? assignment = provider.attendanceAssignments.first;
    TimeOfDay checkIn = _parseTime(assignment.startTime);
    TimeOfDay checkOut = _parseTime(assignment.endTime);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chấm công nhân viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: assignment?.assignmentId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ca đã phân'),
                items: provider.attendanceAssignments
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: item.assignmentId,
                        child: Text(
                          '${_date(item.workDate)} • ${item.shiftName ?? 'Ca làm việc'}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final selected = provider.attendanceAssignments.firstWhere(
                    (item) => item.assignmentId == value,
                  );
                  setDialogState(() {
                    assignment = selected;
                    checkIn = _parseTime(selected.startTime);
                    checkOut = _parseTime(selected.endTime);
                  });
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Giờ vào'),
                trailing: Text(checkIn.format(context)),
                onTap: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: checkIn,
                  );
                  if (value != null) setDialogState(() => checkIn = value);
                },
              ),
              ListTile(
                title: const Text('Giờ ra'),
                trailing: Text(checkOut.format(context)),
                onTap: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: checkOut,
                  );
                  if (value != null) setDialogState(() => checkOut = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final selected = assignment;
                if (selected == null) return;
                final day = selected.workDate;
                final checkInDateTime = DateTime(
                  day.year,
                  day.month,
                  day.day,
                  checkIn.hour,
                  checkIn.minute,
                );
                var checkOutDateTime = DateTime(
                  day.year,
                  day.month,
                  day.day,
                  checkOut.hour,
                  checkOut.minute,
                );
                if (!checkOutDateTime.isAfter(checkInDateTime)) {
                  checkOutDateTime = checkOutDateTime.add(
                    const Duration(days: 1),
                  );
                }
                final success = await provider.saveManualAttendance(
                  shiftAssignmentId: selected.assignmentId,
                  checkInTime: checkInDateTime,
                  checkOutTime: checkOutDateTime,
                );
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Lưu chấm công'),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month + 1, 0),
      helpText: 'Chọn một ngày trong tháng cần xem',
    );
    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });
    await _loadHistory();
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _time(DateTime? value) {
    if (value == null) return '--:--';
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Duration _workedDuration(Iterable<AttendanceRecord> records) {
    return records.fold(Duration.zero, (total, record) {
      if (record.checkInTime == null || record.checkOutTime == null)
        return total;
      final duration = record.checkOutTime!.difference(record.checkInTime!);
      return duration.isNegative ? total : total + duration;
    });
  }

  String _duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  Map<DateTime, List<AttendanceRecord>> _groupByDay(
    List<AttendanceRecord> records,
  ) {
    final result = <DateTime, List<AttendanceRecord>>{};
    for (final record in records) {
      final day = DateTime(
        record.workDate.year,
        record.workDate.month,
        record.workDate.day,
      );
      result.putIfAbsent(day, () => []).add(record);
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectedEmployeeId != null) {
              setState(() => _selectedEmployeeId = null);
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          _selectedEmployeeId == null
              ? 'Chấm công nhân viên'
              : 'Chi tiết chấm công',
        ),
      ),
      body: Consumer<HrProvider>(
        builder: (context, provider, _) {
          if (_selectedEmployeeId == null) {
            return _buildEmployeeSelection(provider);
          }
          final grouped = _groupByDay(provider.attendanceHistory);
          return _buildEmployeeDetail(provider, grouped);
        },
      ),
    );
  }

  Widget _buildEmployeeSelection(HrProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) return _buildError(provider.error!);
    final employees = provider.employees
        .where((employee) => employee['roleName'] != 'Store Manager')
        .toList();
    if (employees.isEmpty) {
      return const Center(child: Text('Không có nhân viên trong chi nhánh.'));
    }
    return RefreshIndicator(
      onRefresh: _loadEmployees,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Chọn nhân viên để chấm công',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...employees.map(
            (employee) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    employee['fullName'].toString()[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(employee['fullName']?.toString() ?? ''),
                subtitle: Text(employee['roleName']?.toString() ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  setState(() {
                    _selectedEmployeeId = employee['userId'] as int;
                  });
                  await _loadHistory();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDetail(
    HrProvider provider,
    Map<DateTime, List<AttendanceRecord>> grouped,
  ) {
    final employee = provider.employees.firstWhere(
      (item) => item['userId'] == _selectedEmployeeId,
    );
    final todayAssignments = provider.attendanceAssignments
        .where((item) => _sameDay(item.workDate, _now))
        .toList();
    final todayRecords = provider.attendanceHistory
        .where((item) => _sameDay(item.workDate, _now))
        .toList();
    final assignment = todayAssignments.isEmpty ? null : todayAssignments.first;
    final attendance = todayRecords.isEmpty ? null : todayRecords.first;
    final checkedIn = attendance?.checkInTime != null;
    final checkedOut = attendance?.checkOutTime != null;
    final statusLabel = checkedIn && !checkedOut
        ? 'ĐANG LÀM VIỆC'
        : checkedOut
        ? 'ĐÃ TAN CA'
        : 'CHƯA VÀO CA';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Chip(label: Text(statusLabel)),
              Text(
                '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Text(_date(_now)),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      employee['fullName'].toString()[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(employee['fullName']?.toString() ?? ''),
                  subtitle: Text(
                    assignment == null
                        ? 'Chưa được phân ca hôm nay'
                        : '${assignment.shiftName} • ${assignment.displayTime}',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                      ),
                      onPressed:
                          assignment != null && (!checkedIn || checkedOut)
                          ? () => _checkInNow(provider, assignment)
                          : null,
                      icon: const Icon(Icons.login),
                      label: const Text('Vào ca'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: assignment != null && checkedIn && !checkedOut
                          ? () =>
                                _checkOutNow(provider, assignment, attendance!)
                          : null,
                      icon: const Icon(Icons.logout),
                      label: const Text('Tan ca'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildSummary(provider.attendanceHistory),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch sử gần đây',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: _pickMonth,
                child: const Text('Chọn tháng'),
              ),
            ],
          ),
        ),
        if (provider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (grouped.isEmpty)
          const Expanded(
            child: Center(child: Text('Chưa có lịch sử chấm công.')),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: grouped.entries
                  .map((entry) => _buildDayCard(entry.key, entry.value))
                  .toList(),
            ),
          ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _checkInNow(
    HrProvider provider,
    ShiftAssignment assignment,
  ) async {
    final success = await provider.saveManualAttendance(
      shiftAssignmentId: assignment.assignmentId,
      checkInTime: _now,
    );
    if (success) await _loadHistory();
  }

  Future<void> _checkOutNow(
    HrProvider provider,
    ShiftAssignment assignment,
    AttendanceRecord attendance,
  ) async {
    final success = await provider.saveManualAttendance(
      shiftAssignmentId: assignment.assignmentId,
      checkInTime: attendance.checkInTime!,
      checkOutTime: _now,
    );
    if (success) await _loadHistory();
  }

  Widget _buildFilters(HrProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value:
                provider.employees.any(
                  (employee) => employee['userId'] == _selectedEmployeeId,
                )
                ? _selectedEmployeeId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Chọn nhân viên',
              prefixIcon: Icon(Icons.person_search),
            ),
            items: provider.employees
                .map(
                  (employee) => DropdownMenuItem<int>(
                    value: employee['userId'] as int,
                    child: Text(employee['fullName']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedEmployeeId = value);
              _loadHistory();
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tháng báo cáo',
                prefixIcon: Icon(Icons.calendar_month),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                'Tháng ${_selectedMonth.month}/${_selectedMonth.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<AttendanceRecord> history) {
    final completed = history
        .where((item) => item.checkInTime != null && item.checkOutTime != null)
        .toList();
    final total = _workedDuration(completed);
    final days = completed
        .map(
          (item) => DateTime(
            item.workDate.year,
            item.workDate.month,
            item.workDate.day,
          ),
        )
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          _summaryCard('Ngày đã làm', '$days', Icons.event_available),
          const SizedBox(width: 12),
          _summaryCard('Tổng giờ', _duration(total), Icons.schedule),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(DateTime day, List<AttendanceRecord> records) {
    final worked = _workedDuration(records);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _date(day),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _duration(worked),
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            ...records.map(_buildAttendanceRow),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRow(AttendanceRecord record) {
    final complete = record.checkInTime != null && record.checkOutTime != null;
    final duration = complete
        ? record.checkOutTime!.difference(record.checkInTime!)
        : Duration.zero;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(record.shiftName ?? 'Ca làm việc')),
          Text('${_time(record.checkInTime)} → ${_time(record.checkOutTime)}'),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              complete ? _duration(duration) : 'Đang làm',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: complete ? AppTheme.successGreen : AppTheme.accentAmber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: _loadHistory, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
