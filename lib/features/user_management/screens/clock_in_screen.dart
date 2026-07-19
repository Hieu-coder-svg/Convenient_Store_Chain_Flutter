import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/shift.dart';
import '../providers/hr_provider.dart';

class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  ShiftAssignment? _selectedAssignment;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchedule());
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    final provider = context.read<HrProvider>();
    final today = DateTime.now();
    final currentWeekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
    await provider.loadMySchedule(weekStart: currentWeekStart);
    if (!mounted) return;
    final todayAssignments = _getTodayAssignments(provider);
    setState(() {
      if (_selectedAssignment == null ||
          !todayAssignments.any(
            (item) => item.assignmentId == _selectedAssignment!.assignmentId,
          )) {
        _selectedAssignment = todayAssignments.isEmpty
            ? null
            : todayAssignments.first;
      }
    });
  }

  List<ShiftAssignment> _getTodayAssignments(HrProvider provider) {
    final today = DateTime.now();
    final assignments = provider.mySchedule
        .where(
          (item) =>
              item.workDate.year == today.year &&
              item.workDate.month == today.month &&
              item.workDate.day == today.day &&
              item.status.toLowerCase() != 'cancelled',
        )
        .toList();
    assignments.sort(
      (left, right) => _scheduledStart(left).compareTo(_scheduledStart(right)),
    );
    return assignments;
  }

  DateTime _scheduledStart(ShiftAssignment assignment) {
    final time = _parseShiftTime(assignment.startTime);
    final day = assignment.workDate;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  DateTime _scheduledEnd(ShiftAssignment assignment) {
    final start = _scheduledStart(assignment);
    final time = _parseShiftTime(assignment.endTime);
    var end = DateTime(
      start.year,
      start.month,
      start.day,
      time.hour,
      time.minute,
    );
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return end;
  }

  TimeOfDay _parseShiftTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  bool _canCheckInNow(ShiftAssignment? assignment) {
    if (assignment == null) return false;
    final now = DateTime.now();
    final opensAt = _scheduledStart(
      assignment,
    ).subtract(const Duration(minutes: 20));
    return !now.isBefore(opensAt) && !now.isAfter(_scheduledEnd(assignment));
  }

  void _handleCheckIn(HrProvider provider) async {
    if (_selectedAssignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ca làm việc')),
      );
      return;
    }

    if (!_canCheckInNow(_selectedAssignment)) {
      final opensAt = _scheduledStart(
        _selectedAssignment!,
      ).subtract(const Duration(minutes: 20));
      final now = DateTime.now();
      final message = now.isBefore(opensAt)
          ? 'Chưa đến giờ vào ca. Bạn có thể chấm công từ ${_formatTime(opensAt)}.'
          : 'Ca làm việc đã kết thúc, không thể chấm công vào ca.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận vào ca'),
        content: Text(
          'Bạn đang chấm công vào ca:\n${_selectedAssignment!.shiftName ?? ''}\n(${_selectedAssignment!.displayTime})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vào ca'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Use dummy GPS (0,0) – in production use geolocator package
    final success = await provider.checkIn(
      shiftAssignmentId: _selectedAssignment!.assignmentId,
      latitude: 0.0,
      longitude: 0.0,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chấm công vào ca thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Chấm công thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCheckOut(HrProvider provider) async {
    final attendance = provider.todayAttendance;
    if (attendance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có dữ liệu vào ca hôm nay')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận tan ca'),
        content: const Text('Bạn chắc chắn muốn kết thúc ca làm việc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tan ca'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await provider.checkOut(
      attendanceId: attendance.attendanceId,
      latitude: 0.0,
      longitude: 0.0,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tan ca thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Chấm công thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Chấm công'),
        actions: [
          Consumer<HrProvider>(
            builder: (context, provider, _) {
              final isActive =
                  provider.todayAttendance?.isCheckedIn == true &&
                  provider.todayAttendance?.isCheckedOut != true;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isActive ? AppTheme.successGreen : Colors.grey)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppTheme.successGreen : Colors.grey,
                  ),
                ),
                child: Text(
                  isActive ? 'Đang làm việc' : 'Chưa vào ca',
                  style: TextStyle(
                    color: isActive ? AppTheme.successGreen : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<HrProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final todayShifts = _getTodayAssignments(provider);
          final attendance = provider.todayAttendance;
          final isCheckedIn = attendance?.isCheckedIn == true;
          final isCheckedOut = attendance?.isCheckedOut == true;

          return RefreshIndicator(
            onRefresh: _loadSchedule,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Clock display
                  _buildClockDisplay(),

                  // Profile card
                  if (authUser != null)
                    _buildProfileCard(authUser.fullName, authUser.roleName),

                  // Today's shift selector
                  if (todayShifts.isNotEmpty && !isCheckedIn)
                    _buildShiftSelector(todayShifts),

                  if (!isCheckedIn)
                    _buildCheckInAvailability(_selectedAssignment),

                  // Action buttons
                  _buildActionButtons(
                    provider: provider,
                    isCheckedIn: isCheckedIn,
                    isCheckedOut: isCheckedOut,
                  ),

                  // Status banner
                  if (attendance != null)
                    _buildStatusBanner(
                      attendance.isCheckedOut
                          ? attendance.checkOutStatus
                          : attendance.checkInStatus,
                      minutes: attendance.isCheckedOut
                          ? attendance.earlyMinutes
                          : attendance.lateMinutes,
                      isCheckOut: attendance.isCheckedOut,
                    ),

                  // Recent history
                  _buildRecentHistory(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClockDisplay() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} tháng ${now.month}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(dateStr, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(String fullName, String roleName) {
    final initials = fullName.isNotEmpty
        ? fullName.substring(0, 1).toUpperCase()
        : 'U';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roleName,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftSelector(List<ShiftAssignment> shifts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<ShiftAssignment>(
        initialValue: _selectedAssignment,
        decoration: InputDecoration(
          labelText: 'Chọn ca làm việc hôm nay',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        items: shifts.map((s) {
          return DropdownMenuItem<ShiftAssignment>(
            value: s,
            child: Text('${s.shiftName ?? 'Ca'} (${s.displayTime})'),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedAssignment = val),
      ),
    );
  }

  Widget _buildActionButtons({
    required HrProvider provider,
    required bool isCheckedIn,
    required bool isCheckedOut,
  }) {
    final canCheckIn =
        !isCheckedIn && !isCheckedOut && _canCheckInNow(_selectedAssignment);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canCheckIn ? () => _handleCheckIn(provider) : null,
              icon: const Icon(Icons.login),
              label: const Text('Vào ca'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (isCheckedIn && !isCheckedOut)
                  ? () => _handleCheckOut(provider)
                  : null,
              icon: const Icon(Icons.logout),
              label: const Text('Tan ca'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInAvailability(ShiftAssignment? assignment) {
    if (assignment == null) {
      return _buildInfoBanner(
        message: 'Bạn không có ca làm việc hôm nay.',
        icon: Icons.event_busy_outlined,
        color: Colors.grey.shade700,
        backgroundColor: Colors.grey.shade100,
      );
    }

    final now = DateTime.now();
    final start = _scheduledStart(assignment);
    final end = _scheduledEnd(assignment);
    final opensAt = start.subtract(const Duration(minutes: 20));

    if (now.isBefore(opensAt)) {
      return _buildInfoBanner(
        message:
            'Nút Vào ca sẽ mở lúc ${_formatTime(opensAt)} (trước ca 20 phút).',
        icon: Icons.schedule_outlined,
        color: AppTheme.primaryBlue,
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: .08),
      );
    }
    if (now.isAfter(end)) {
      return _buildInfoBanner(
        message: 'Ca làm việc đã kết thúc.',
        icon: Icons.event_busy_outlined,
        color: AppTheme.dangerRed,
        backgroundColor: AppTheme.dangerRed.withValues(alpha: .08),
      );
    }
    if (now.isAfter(start.add(const Duration(minutes: 15)))) {
      return _buildInfoBanner(
        message:
            'Bạn đã trễ quá 15 phút. Vào ca lúc này sẽ được ghi nhận đi muộn.',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.dangerRed,
        backgroundColor: AppTheme.dangerRed.withValues(alpha: .08),
      );
    }

    return _buildInfoBanner(
      message: now.isBefore(start)
          ? 'Đã có thể chấm công vào ca.'
          : 'Bạn đang trong thời gian vào ca đúng giờ.',
      icon: Icons.check_circle_outline,
      color: AppTheme.successGreen,
      backgroundColor: AppTheme.successGreen.withValues(alpha: .08),
    );
  }

  Widget _buildInfoBanner({
    required String message,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
    String? status, {
    required int minutes,
    required bool isCheckOut,
  }) {
    if (status == null) return const SizedBox.shrink();
    final isLate =
        status.toLowerCase().contains('late') ||
        status.toLowerCase().contains('muộn');
    final isEarly =
        status.toLowerCase().contains('early') ||
        status.toLowerCase().contains('sớm');
    final isWarning = isLate || isEarly;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isWarning ? AppTheme.dangerRed : AppTheme.successGreen)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning ? AppTheme.dangerRed : AppTheme.successGreen,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            color: isWarning ? AppTheme.dangerRed : AppTheme.successGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCheckOut
                  ? isEarly
                        ? 'Đã tan ca sớm${minutes > 0 ? ' $minutes phút' : ''}'
                        : 'Đã tan ca'
                  : isLate
                  ? 'Đi muộn${minutes > 0 ? ' $minutes phút' : ''}'
                  : 'Đã vào ca đúng giờ',
              style: TextStyle(
                color: isWarning ? AppTheme.dangerRed : AppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory(HrProvider provider) {
    final recent = provider.mySchedule.take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ca gần đây', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...recent.map(
            (s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.access_time,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                title: Text(
                  s.shiftName ?? 'Ca làm việc',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${s.workDate.day}/${s.workDate.month} • ${s.displayTime}',
                ),
                trailing: Chip(
                  label: Text(
                    s.status,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: s.status == 'Scheduled'
                      ? AppTheme.primaryBlue
                      : AppTheme.successGreen,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
