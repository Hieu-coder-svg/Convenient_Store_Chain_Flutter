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
                } else if (mounted) {
                  await _showOperationError(
                    title: shift == null
                        ? 'Không thể tạo ca'
                        : 'Không thể cập nhật ca',
                    message:
                        provider.error ?? 'Có lỗi xảy ra. Vui lòng thử lại.',
                  );
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

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _showOperationError({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 30,
          ),
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAssignShiftDialog() async {
    final provider = context.read<HrProvider>();
    if (provider.shiftTemplates.isEmpty || provider.employees.isEmpty) {
      await _showOperationError(
        title: 'Chưa thể phân ca',
        message: provider.shiftTemplates.isEmpty && provider.employees.isEmpty
            ? 'Chưa có mẫu ca và nhân viên. Vui lòng tạo mẫu ca và thêm nhân viên trước.'
            : provider.shiftTemplates.isEmpty
            ? 'Chưa có mẫu ca làm việc. Vui lòng tạo mẫu ca trước khi phân ca.'
            : 'Chưa có nhân viên để phân ca. Vui lòng thêm nhân viên trước.',
      );
      return;
    }
    final today = _dateOnly(DateTime.now());
    int? employeeId;
    int? shiftId;
    var workDate = _dateOnly(provider.weekStart).isBefore(today)
        ? today
        : _dateOnly(provider.weekStart);
    String? dialogError;
    var isSubmitting = false;

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
                isExpanded: true,
                items: provider.employees
                    .where((e) => e['roleName'] != 'Store Manager')
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e['userId'] as int,
                        child: Text(e['fullName']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() {
                  employeeId = value;
                  dialogError = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Ca làm việc'),
                isExpanded: true,
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
                onChanged: (value) => setDialogState(() {
                  shiftId = value;
                  dialogError = null;
                }),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('Ngày làm việc'),
                subtitle: const Text('Chỉ chọn hôm nay hoặc ngày tương lai'),
                trailing: Text(
                  _formatDate(workDate),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    initialDate: workDate,
                    firstDate: today,
                    lastDate: DateTime(today.year + 5, 12, 31),
                    locale: const Locale('vi', 'VN'),
                    helpText: 'CHỌN NGÀY LÀM VIỆC',
                    cancelText: 'HỦY',
                    confirmText: 'CHỌN',
                  );
                  if (value != null) {
                    setDialogState(() {
                      workDate = value;
                      dialogError = null;
                    });
                  }
                },
              ),
              if (dialogError != null) _buildInlineError(dialogError!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (employeeId == null || shiftId == null) {
                        setDialogState(() {
                          dialogError = employeeId == null && shiftId == null
                              ? 'Vui lòng chọn nhân viên và ca làm việc.'
                              : employeeId == null
                              ? 'Vui lòng chọn nhân viên.'
                              : 'Vui lòng chọn ca làm việc.';
                        });
                        return;
                      }
                      if (_dateOnly(workDate).isBefore(today)) {
                        setDialogState(() {
                          dialogError =
                              'Không thể phân ca cho ngày trong quá khứ.';
                        });
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        dialogError = null;
                      });
                      final success = await provider.assignShift(
                        employeeId: employeeId!,
                        shiftId: shiftId!,
                        workDate: workDate,
                      );
                      if (success && dialogContext.mounted && mounted) {
                        final branchId = this.context
                            .read<AuthProvider>()
                            .currentUser
                            ?.branchId;
                        final selectedWeekStart = _dateOnly(
                          workDate,
                        ).subtract(Duration(days: workDate.weekday - 1));
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã phân ca thành công.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (branchId != null) {
                          await provider.loadScheduleBuilder(
                            branchId,
                            weekStart: selectedWeekStart,
                          );
                        }
                      } else if (dialogContext.mounted) {
                        setDialogState(() {
                          isSubmitting = false;
                          dialogError =
                              provider.error ?? 'Không thể phân ca làm việc.';
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Phân ca'),
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
    final selected = await showModalBottomSheet<ShiftModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => FractionallySizedBox(
        heightFactor: .72,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản lý ca làm việc',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Chọn một ca để chỉnh sửa hoặc xóa',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: templates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final shift = templates[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            8,
                            8,
                          ),
                          onTap: () => Navigator.pop(dialogContext, shift),
                          leading: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          title: Text(
                            shift.shiftName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(shift.displayTime),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Sửa ca',
                                color: AppTheme.primaryBlue,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    Navigator.pop(dialogContext, shift),
                              ),
                              IconButton(
                                tooltip: 'Xóa ca',
                                color: const Color(0xFFDC2626),
                                icon: const Icon(Icons.delete_outline),
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
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Hủy'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Xóa'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  if (!mounted) return;
                                  final provider = this.context
                                      .read<HrProvider>();
                                  final success = await provider
                                      .deleteShiftTemplate(shift.shiftId);
                                  if (!mounted) return;
                                  if (success && dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(
                                      this.context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã xóa ca làm việc.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else {
                                    await _showOperationError(
                                      title: 'Không thể xóa ca',
                                      message:
                                          provider.error ??
                                          'Ca này chưa thể xóa. Vui lòng thử lại.',
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          buttonPadding: EdgeInsets.zero,
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                      if (success && dialogContext.mounted && mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã xóa nhân viên khỏi ca.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (mounted) {
                        await _showOperationError(
                          title: 'Không thể xóa khỏi ca',
                          message:
                              provider.error ??
                              'Không thể xóa nhân viên khỏi ca. Vui lòng thử lại.',
                        );
                      }
                    },
                    child: const Text('Xóa khỏi ca'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      final success = await provider.updateAssignment(
                        assignmentId: assignment.assignmentId,
                        employeeId: employeeId,
                      );
                      if (success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      } else if (mounted) {
                        await _showOperationError(
                          title: 'Không thể đổi nhân viên',
                          message:
                              provider.error ??
                              'Không thể cập nhật nhân viên cho ca này.',
                        );
                      }
                    },
                    child: const Text('Đổi nhân viên'),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
              ],
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
              else if (provider.error != null && provider.storeSchedule.isEmpty)
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 19,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.shiftName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  a.displayTime,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        a.employeeName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sửa ca làm việc',
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () {
              _showEditAssignmentDialog(a);
            },
          ),
        ],
      ),
    );
  }
}
