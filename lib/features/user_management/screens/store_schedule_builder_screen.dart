import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/shift.dart';
import '../providers/hr_provider.dart';

class StoreScheduleBuilderScreen extends StatefulWidget {
  const StoreScheduleBuilderScreen({super.key});

  @override
  State<StoreScheduleBuilderScreen> createState() =>
      _StoreScheduleBuilderScreenState();
}

class _StoreScheduleBuilderScreenState
    extends State<StoreScheduleBuilderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = context.read<AuthProvider>().currentUser;
    final branchId = auth?.branchId;
    if (branchId != null) {
      context.read<HrProvider>().loadScheduleBuilder(branchId);
    }
  }

  void _goToPrevWeek() {
    final auth = context.read<AuthProvider>().currentUser;
    final branchId = auth?.branchId;
    if (branchId == null) return;
    final provider = context.read<HrProvider>();
    final newStart = provider.weekStart.subtract(const Duration(days: 7));
    provider.loadScheduleBuilder(branchId, weekStart: newStart);
  }

  void _goToNextWeek() {
    final auth = context.read<AuthProvider>().currentUser;
    final branchId = auth?.branchId;
    if (branchId == null) return;
    final provider = context.read<HrProvider>();
    final newStart = provider.weekStart.add(const Duration(days: 7));
    provider.loadScheduleBuilder(branchId, weekStart: newStart);
  }

  Future<void> _showCreateShiftDialog([ShiftModel? shift]) async {
    final branchId = context.read<AuthProvider>().currentUser?.branchId;
    if (branchId == null) return;
    final nameController = TextEditingController(text: shift?.shiftName ?? '');
    var start = shift == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : _parseTime(shift.startTime);
    var end = shift == null
        ? const TimeOfDay(hour: 16, minute: 0)
        : _parseTime(shift.endTime);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(shift == null ? 'Tạo ca làm việc' : 'Sửa ca làm việc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên ca'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Giờ bắt đầu'),
                trailing: Text(start.format(context)),
                onTap: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (value != null) setDialogState(() => start = value);
                },
              ),
              ListTile(
                title: const Text('Giờ kết thúc'),
                trailing: Text(end.format(context)),
                onTap: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (value != null) setDialogState(() => end = value);
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
                if (nameController.text.trim().isEmpty) return;
                String time(TimeOfDay value) =>
                    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';
                final provider = context.read<HrProvider>();
                final success = shift == null
                    ? await provider.createShiftTemplate(
                        branchId: branchId,
                        shiftName: nameController.text.trim(),
                        startTime: time(start),
                        endTime: time(end),
                      )
                    : await provider.updateShiftTemplate(
                        shiftId: shift.shiftId,
                        shiftName: nameController.text.trim(),
                        startTime: time(start),
                        endTime: time(end),
                      );
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(shift == null ? 'Tạo ca' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (mounted) _loadData();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  Future<void> _showAssignShiftDialog() async {
    final provider = context.read<HrProvider>();
    if (provider.shiftTemplates.isEmpty || provider.employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần có ca làm việc và nhân viên trước khi phân ca.'),
        ),
      );
      return;
    }
    int? employeeId;
    int? shiftId;
    var workDate = provider.weekStart;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Phân ca cho nhân viên'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Nhân viên'),
                items: provider.employees
                    .where((e) => e['roleName'] != 'Store Manager')
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e['userId'] as int,
                        child: Text(e['fullName']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => employeeId = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Ca làm việc'),
                items: provider.shiftTemplates
                    .map(
                      (shift) => DropdownMenuItem<int>(
                        value: shift.shiftId,
                        child: Text(
                          '${shift.shiftName} (${shift.displayTime})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => shiftId = value,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Ngày làm việc'),
                trailing: Text(_formatDate(workDate)),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: workDate,
                    firstDate: provider.weekStart,
                    lastDate: provider.weekEnd,
                  );
                  if (value != null) setDialogState(() => workDate = value);
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
                if (employeeId == null || shiftId == null) return;
                final success = await provider.assignShift(
                  employeeId: employeeId!,
                  shiftId: shiftId!,
                  workDate: workDate,
                );
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Phân ca'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditShiftPicker() async {
    final templates = context.read<HrProvider>().shiftTemplates;
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có ca làm việc để sửa.')),
      );
      return;
    }
    final selected = await showDialog<ShiftModel>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Chọn ca cần sửa'),
        children: templates
            .map(
              (shift) => ListTile(
                onTap: () => Navigator.pop(dialogContext, shift),
                leading: const Icon(Icons.schedule),
                title: Text(shift.shiftName),
                subtitle: Text(shift.displayTime),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Sửa ca',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => Navigator.pop(dialogContext, shift),
                    ),
                    IconButton(
                      tooltip: 'Xóa ca',
                      color: Colors.red,
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: dialogContext,
                          builder: (context) => AlertDialog(
                            title: const Text('Xóa ca làm việc?'),
                            content: Text(
                              'Bạn có chắc muốn xóa “${shift.shiftName}”?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        final provider = context.read<HrProvider>();
                        final success = await provider.deleteShiftTemplate(
                          shift.shiftId,
                        );
                        if (!mounted) return;
                        if (success && dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã xóa ca làm việc.'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                provider.error ?? 'Không thể xóa ca làm việc',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected != null && mounted) await _showCreateShiftDialog(selected);
  }

  Future<void> _showEditAssignmentDialog(ShiftAssignment assignment) async {
    final provider = context.read<HrProvider>();
    var employeeId = assignment.employeeId;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nhân viên làm ca'),
          content: DropdownButtonFormField<int>(
            initialValue: employeeId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Nhân viên'),
            items: provider.employees
                .where((employee) => employee['roleName'] != 'Store Manager')
                .map(
                  (employee) => DropdownMenuItem<int>(
                    value: employee['userId'] as int,
                    child: Text(employee['fullName']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => employeeId = value);
            },
          ),
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa nhân viên khỏi ca?'),
                    content: Text(
                      'Xóa ${assignment.employeeName ?? 'nhân viên'} khỏi ${assignment.shiftName ?? 'ca này'}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                final success = await provider.deleteAssignment(
                  assignment.assignmentId,
                );
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.person_remove),
              label: const Text('Xóa khỏi ca'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final success = await provider.updateAssignment(
                  assignmentId: assignment.assignmentId,
                  employeeId: employeeId,
                );
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Đổi nhân viên'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _dayName(DateTime d) {
    const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return names[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Xếp lịch làm việc'),
      ),
      body: Consumer<HrProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildWeekNavBar(provider),
              if (provider.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        TextButton(
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (provider.storeSchedule.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Chưa có lịch làm việc trong tuần này.'),
                  ),
                )
              else
                Expanded(child: _buildScheduleList(provider)),
              _buildActionBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showCreateShiftDialog,
                icon: const Icon(Icons.add_alarm),
                label: const Text('Tạo ca'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showEditShiftPicker,
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Sửa ca'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton.icon(
                onPressed: _showAssignShiftDialog,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Phân ca'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekNavBar(HrProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.isLoading ? null : _goToPrevWeek,
          ),
          Text(
            '${_formatDate(provider.weekStart)} - ${_formatDate(provider.weekEnd)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.isLoading ? null : _goToNextWeek,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(HrProvider provider) {
    // Generate 7 days of the week
    final days = List.generate(
      7,
      (i) => provider.weekStart.add(Duration(days: i)),
    );

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final key =
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          final assignments = provider.scheduleByDate[key] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _dayName(day),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(day),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${assignments.length} ca',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (assignments.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Không có ca làm việc',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    ...assignments.map((a) => _buildAssignmentTile(a)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentTile(ShiftAssignment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${a.shiftName ?? ''} (${a.displayTime})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            a.employeeName ?? '',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          IconButton(
            tooltip: 'Sửa ca làm việc',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () {
              _showEditAssignmentDialog(a);
            },
          ),
        ],
      ),
    );
  }
}
