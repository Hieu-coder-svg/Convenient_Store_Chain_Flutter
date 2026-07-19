import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance.dart';
import '../providers/hr_provider.dart';

class WorkHistoryScreen extends StatefulWidget {
  const WorkHistoryScreen({super.key});

  @override
  State<WorkHistoryScreen> createState() => _WorkHistoryScreenState();
}

class _WorkHistoryScreenState extends State<WorkHistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  int? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool _isManager(String? roleName) {
    final role = roleName?.replaceAll(' ', '').toLowerCase();
    return role == 'storemanager' || role == 'systemadmin';
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().currentUser;
    final provider = context.read<HrProvider>();
    final manager = _isManager(user?.roleName);
    if (manager && user?.branchId != null && provider.employees.isEmpty) {
      await provider.loadAttendanceEmployees(user!.branchId!);
    }
    if (!mounted) return;
    await provider.loadWorkHistory(
      branchId: manager ? user?.branchId : null,
      employeeId: manager ? _selectedEmployeeId : null,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: 'CHỌN KHOẢNG NGÀY',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      saveText: 'LƯU',
    );
    if (range == null || !mounted) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final manager = _isManager(user?.roleName);
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
        title: Text(
          manager ? 'Lịch sử làm việc cửa hàng' : 'Lịch sử làm việc',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<HrProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: _load,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildFilters(provider, manager)),
                SliverToBoxAdapter(child: _buildSummary(provider.workHistory)),
                if (provider.isLoading && provider.workHistory.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildMessage(
                      Icons.cloud_off_outlined,
                      provider.error!,
                      actionLabel: 'Thử lại',
                      onAction: _load,
                    ),
                  )
                else if (provider.workHistory.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyHistory(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    sliver: SliverList.builder(
                      itemCount: _groupByDay(provider.workHistory).length,
                      itemBuilder: (context, index) {
                        final group = _groupByDay(provider.workHistory)[index];
                        return _buildDayGroup(group.$1, group.$2, manager);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(HrProvider provider, bool manager) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6F2)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_outlined,
                    color: Color(0xFF24469A),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Khoảng thời gian',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(_startDate)}  –  '
                          '${DateFormat('dd/MM/yyyy').format(_endDate)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          if (manager) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              initialValue: _selectedEmployeeId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Nhân viên',
                prefixIcon: const Icon(Icons.person_search_outlined),
                filled: true,
                fillColor: const Color(0xFFF4F7FD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Tất cả nhân viên'),
                ),
                ...provider.employees.map(
                  (employee) => DropdownMenuItem<int?>(
                    value: employee['userId'] as int,
                    child: Text(employee['fullName']?.toString() ?? ''),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedEmployeeId = value);
                _load();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(List<WorkHistoryItem> items) {
    final worked = items.where((item) => item.attendanceId > 0).length;
    final late = items.where((item) => item.isLate).length;
    final early = items.where((item) => item.isEarlyLeave).length;
    final absent = items.where((item) => item.isAbsent).length;
    return SizedBox(
      height: 92,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _summaryCard(
            'Đã đi làm',
            worked,
            Icons.task_alt,
            const Color(0xFF0A9B64),
          ),
          _summaryCard(
            'Đi muộn',
            late,
            Icons.schedule,
            const Color(0xFFE88616),
          ),
          _summaryCard('Về sớm', early, Icons.logout, const Color(0xFFD95A35)),
          _summaryCard(
            'Vắng mặt',
            absent,
            Icons.person_off_outlined,
            const Color(0xFFD93845),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int value, IconData icon, Color color) {
    return Container(
      width: 122,
      margin: const EdgeInsets.only(right: 10, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(DateTime, List<WorkHistoryItem>)> _groupByDay(
    List<WorkHistoryItem> items,
  ) {
    final groups = <DateTime, List<WorkHistoryItem>>{};
    for (final item in items) {
      final day = DateTime(
        item.workDate.year,
        item.workDate.month,
        item.workDate.day,
      );
      groups.putIfAbsent(day, () => []).add(item);
    }
    return groups.entries.map((entry) => (entry.key, entry.value)).toList();
  }

  Widget _buildDayGroup(
    DateTime day,
    List<WorkHistoryItem> items,
    bool manager,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '${_weekday(day.weekday)}, ${DateFormat('dd/MM/yyyy').format(day)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ...items.map((item) => _buildHistoryCard(item, manager)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(WorkHistoryItem item, bool manager) {
    final status = _statusStyle(item.workStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E6F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFEAF0FF),
                child: Text(
                  item.employeeName.isEmpty
                      ? 'N'
                      : item.employeeName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF24469A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (manager)
                      Text(
                        item.employeeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      '${item.shiftName}  •  ${_shortTime(item.scheduledStartTime)}–${_shortTime(item.scheduledEndTime)}',
                      style: TextStyle(
                        fontSize: manager ? 12 : 15,
                        fontWeight: manager ? FontWeight.w500 : FontWeight.w700,
                        color: manager
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
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
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: _timeInfo(
                  Icons.login,
                  'Vào ca',
                  _formatClock(item.checkInTime),
                  item.lateMinutes > 0 ? 'Muộn ${item.lateMinutes} phút' : null,
                ),
              ),
              Container(width: 1, height: 38, color: const Color(0xFFE1E5ED)),
              const SizedBox(width: 14),
              Expanded(
                child: _timeInfo(
                  Icons.logout,
                  'Tan ca',
                  _formatClock(item.checkOutTime),
                  item.earlyMinutes > 0
                      ? 'Sớm ${item.earlyMinutes} phút'
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeInfo(IconData icon, String label, String time, String? detail) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF49619B)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail != null)
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFD66A18),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  (String, Color) _statusStyle(String status) {
    return switch (status) {
      'Completed' => ('Đã hoàn thành', const Color(0xFF0A9462)),
      'Late' => ('Đi muộn', const Color(0xFFE47B13)),
      'EarlyLeave' => ('Về sớm', const Color(0xFFD85B35)),
      'LateAndEarlyLeave' => ('Muộn & về sớm', const Color(0xFFD13B45)),
      'Working' => ('Đang làm việc', const Color(0xFF1769C2)),
      'LateWorking' => ('Đang làm • đi muộn', const Color(0xFFE47B13)),
      'Absent' => ('Vắng mặt', const Color(0xFFD13B45)),
      'NotCheckedIn' => ('Chưa vào ca', const Color(0xFFC47A00)),
      'MissingCheckout' => ('Chưa tan ca', const Color(0xFFD13B45)),
      'LateMissingCheckout' => (
        'Đi muộn • chưa tan ca',
        const Color(0xFFD13B45),
      ),
      _ => ('Chưa đến ca', const Color(0xFF6E7786)),
    };
  }

  String _formatClock(DateTime? value) =>
      value == null ? '--:--' : DateFormat('HH:mm').format(value);

  String _shortTime(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;

  String _weekday(int weekday) => const {
    1: 'Thứ Hai',
    2: 'Thứ Ba',
    3: 'Thứ Tư',
    4: 'Thứ Năm',
    5: 'Thứ Sáu',
    6: 'Thứ Bảy',
    7: 'Chủ Nhật',
  }[weekday]!;

  Widget _buildMessage(
    IconData icon,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 58, color: AppColors.outline),
            SizedBox(height: 12),
            Text(
              'Chưa có ca làm việc trong khoảng thời gian này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
