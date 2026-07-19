import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/shift.dart';
import '../providers/hr_provider.dart';

class PersonalScheduleScreen extends StatefulWidget {
  const PersonalScheduleScreen({super.key});

  @override
  State<PersonalScheduleScreen> createState() => _PersonalScheduleScreenState();
}

class _PersonalScheduleScreenState extends State<PersonalScheduleScreen> {
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDayIndex = now.weekday - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrProvider>().loadMySchedule(weekStart: _mondayOf(now));
    });
  }

  DateTime _mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  Future<void> _moveWeek(int weekOffset) async {
    final provider = context.read<HrProvider>();
    final targetStart = provider.weekStart.add(Duration(days: weekOffset * 7));
    final now = DateTime.now();
    final currentWeekStart = _mondayOf(now);
    setState(() {
      _selectedDayIndex = _sameDay(targetStart, currentWeekStart)
          ? now.weekday - 1
          : 0;
    });
    await provider.loadMySchedule(weekStart: targetStart);
  }

  Future<void> _reload() async {
    await context.read<HrProvider>().loadMySchedule(
      weekStart: context.read<HrProvider>().weekStart,
    );
  }

  List<ShiftAssignment> _assignmentsForDay(
    List<ShiftAssignment> assignments,
    DateTime day,
  ) {
    return assignments.where((item) => _sameDay(item.workDate, day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF24469A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Lịch cá nhân',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<HrProvider>(
        builder: (context, provider, _) {
          final days = List.generate(
            7,
            (index) => provider.weekStart.add(Duration(days: index)),
          );
          final selectedDay = days[_selectedDayIndex];
          final selectedAssignments = _assignmentsForDay(
            provider.mySchedule,
            selectedDay,
          );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                _buildWeekHeader(provider),
                _buildDayStrip(days, provider.mySchedule),
                _buildWeekSummary(provider.mySchedule),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullWeekday(selectedDay.weekday),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(selectedDay),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EEFA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${selectedAssignments.length} ca',
                          style: const TextStyle(
                            color: Color(0xFF24469A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (provider.isLoading)
                  const SizedBox(
                    height: 230,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error != null)
                  _buildError(provider.error!)
                else if (selectedAssignments.isEmpty)
                  _buildEmptyState(selectedDay)
                else
                  ...selectedAssignments.map(_buildShiftCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekHeader(HrProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF24469A), Color(0xFF3B66C4)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24469A).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: provider.isLoading ? null : () => _moveWeek(-1),
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'TUẦN LÀM VIỆC',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormat('dd/MM').format(provider.weekStart)}  –  '
                  '${DateFormat('dd/MM/yyyy').format(provider.weekEnd)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: provider.isLoading ? null : () => _moveWeek(1),
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip(
    List<DateTime> days,
    List<ShiftAssignment> assignments,
  ) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final selected = index == _selectedDayIndex;
          final hasShift = _assignmentsForDay(assignments, day).isNotEmpty;
          final isToday = _sameDay(day, today);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF24469A) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isToday && !selected
                        ? const Color(0xFF24469A)
                        : const Color(0xFFE0E5EF),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortWeekday(index),
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasShift
                            ? selected
                                  ? Colors.white
                                  : const Color(0xFF24469A)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWeekSummary(List<ShiftAssignment> assignments) {
    final workDays = assignments
        .map(
          (item) => DateTime(
            item.workDate.year,
            item.workDate.month,
            item.workDate.day,
          ),
        )
        .toSet()
        .length;
    final totalMinutes = assignments.fold<int>(
      0,
      (sum, item) => sum + _shiftDurationMinutes(item),
    );
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6F0)),
      ),
      child: Row(
        children: [
          _summaryItem(
            Icons.calendar_today_outlined,
            '${assignments.length}',
            'Tổng số ca',
          ),
          _summaryDivider(),
          _summaryItem(Icons.event_available_outlined, '$workDays', 'Ngày làm'),
          _summaryDivider(),
          _summaryItem(
            Icons.schedule_outlined,
            minutes == 0 ? '${hours}h' : '${hours}h ${minutes}p',
            'Tổng giờ',
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF24469A)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 42, color: const Color(0xFFE2E6EF));

  Widget _buildShiftCard(ShiftAssignment assignment) {
    final status = _dayStatus(assignment.workDate);
    final duration = _shiftDurationMinutes(assignment);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE4F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.schedule, color: Color(0xFF24469A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.shiftName ?? 'Ca làm việc',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      assignment.displayTime,
                      style: const TextStyle(
                        color: Color(0xFF24469A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: status.$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.$1,
                  style: TextStyle(
                    color: status.$2,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timelapse_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Thời lượng',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Text(
                  _durationLabel(duration),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (_sameDay(assignment.workDate, DateTime.now())) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/clock-in'),
                icon: const Icon(Icons.login),
                label: const Text('Đi đến chấm công'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24469A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 46,
            color: AppColors.error,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(DateTime selectedDay) {
    final isToday = _sameDay(selectedDay, DateTime.now());
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E6F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F3F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              size: 34,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isToday ? 'Hôm nay bạn không có ca' : 'Không có ca làm việc',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn một ngày khác để xem lịch được phân.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  int _shiftDurationMinutes(ShiftAssignment assignment) {
    final start = _timeToMinutes(assignment.startTime);
    var end = _timeToMinutes(assignment.endTime);
    if (end <= start) end += 24 * 60;
    return end - start;
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  String _durationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours giờ' : '$hours giờ $remaining phút';
  }

  (String, Color) _dayStatus(DateTime date) {
    final today = DateTime.now();
    final target = DateTime(date.year, date.month, date.day);
    final current = DateTime(today.year, today.month, today.day);
    if (target == current) return ('Hôm nay', const Color(0xFF0A9462));
    if (target.isAfter(current)) return ('Sắp tới', const Color(0xFF1769C2));
    return ('Đã qua', const Color(0xFF6B7280));
  }

  String _shortWeekday(int index) =>
      const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][index];

  String _fullWeekday(int weekday) => const {
    1: 'Thứ Hai',
    2: 'Thứ Ba',
    3: 'Thứ Tư',
    4: 'Thứ Năm',
    5: 'Thứ Sáu',
    6: 'Thứ Bảy',
    7: 'Chủ Nhật',
  }[weekday]!;
}
