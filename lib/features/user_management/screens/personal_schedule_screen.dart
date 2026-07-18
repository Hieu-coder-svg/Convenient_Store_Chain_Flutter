import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/shift.dart';
import '../providers/hr_provider.dart';

class PersonalScheduleScreen extends StatefulWidget {
  const PersonalScheduleScreen({Key? key}) : super(key: key);

  @override
  State<PersonalScheduleScreen> createState() => _PersonalScheduleScreenState();
}

class _PersonalScheduleScreenState extends State<PersonalScheduleScreen> {
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0=Mon…6=Sun

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HrProvider>().loadMySchedule();
    });
  }

  void _prevWeek() {
    final provider = context.read<HrProvider>();
    provider.loadMySchedule(
      weekStart: provider.weekStart.subtract(const Duration(days: 7)),
    );
    setState(() => _selectedDayIndex = 0);
  }

  void _nextWeek() {
    final provider = context.read<HrProvider>();
    provider.loadMySchedule(
      weekStart: provider.weekStart.add(const Duration(days: 7)),
    );
    setState(() => _selectedDayIndex = 0);
  }

  String _dayLabel(int i) =>
      ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][i];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Lịch làm việc'),
      ),
      body: Consumer<HrProvider>(
        builder: (context, provider, _) {
          final days = List.generate(
            7,
            (i) => provider.weekStart.add(Duration(days: i)),
          );
          final selectedDay = days[_selectedDayIndex];
          final dayKey =
              '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
          final todayAssignments = provider.scheduleByDate[dayKey] ?? [];

          return Column(
            children: [
              // Week nav
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: provider.isLoading ? null : _prevWeek,
                    ),
                    Text(
                      'Tuần ${provider.weekStart.day}/${provider.weekStart.month} – ${provider.weekEnd.day}/${provider.weekEnd.month}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: provider.isLoading ? null : _nextWeek,
                    ),
                  ],
                ),
              ),
              // Day strip
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedDayIndex;
                    final day = days[index];
                    final hasShift = provider.scheduleByDate.containsKey(
                      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
                    );
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDayIndex = index),
                      child: Container(
                        width: 52,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _dayLabel(index),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (hasShift && !isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Shifts for selected day
              if (provider.isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (provider.error != null)
                Expanded(
                    child: Center(
                        child: Text(provider.error!,
                            style: const TextStyle(color: Colors.red))))
              else if (todayAssignments.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        context.read<HrProvider>().loadMySchedule(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: todayAssignments.length,
                      itemBuilder: (context, index) =>
                          _buildShiftCard(todayAssignments[index]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShiftCard(ShiftAssignment assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.shiftName ?? 'Ca làm việc',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    assignment.status,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: assignment.status == 'Scheduled'
                      ? AppTheme.primaryBlue
                      : AppTheme.successGreen,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  assignment.displayTime,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Yêu cầu đổi ca'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerRed,
                      side: const BorderSide(color: AppTheme.dangerRed),
                    ),
                    child: const Text('Xin nghỉ phép'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.weekend_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Không có ca làm việc hôm nay!',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy tận hưởng ngày của mình nhé.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
