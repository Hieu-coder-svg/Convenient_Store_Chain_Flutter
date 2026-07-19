import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ShiftTemplatesScreen extends StatefulWidget {
  const ShiftTemplatesScreen({super.key});

  @override
  State<ShiftTemplatesScreen> createState() => _ShiftTemplatesScreenState();
}

class _ShiftTemplatesScreenState extends State<ShiftTemplatesScreen> {
  final List<Map<String, dynamic>> _templates = [
    {
      "name": "Ca Sáng (Morning)",
      "timeRange": "08:00 - 12:00",
      "durationInfo": "4 tiếng | Nghỉ giữa giờ: 0 phút",
      "multiplier": "x1.0",
      "isActive": true,
    },
    {
      "name": "Ca Chiều (Afternoon)",
      "timeRange": "13:00 - 17:00",
      "durationInfo": "4 tiếng | Nghỉ giữa giờ: 0 phút",
      "multiplier": "x1.0",
      "isActive": true,
    },
    {
      "name": "Ca Đêm (Night)",
      "timeRange": "22:00 - 06:00",
      "durationInfo": "8 tiếng | Nghỉ giữa giờ: 60 phút",
      "multiplier": "x1.5",
      "isActive": true,
    },
    {
      "name": "Ca Full-day",
      "timeRange": "08:00 - 17:00",
      "durationInfo": "8 tiếng | Nghỉ giữa giờ: 60 phút",
      "multiplier": "x1.0",
      "isActive": false,
    },
  ];

  void _showCreateEditModal(
    BuildContext context, {
    Map<String, dynamic>? template,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                template == null
                    ? "Thêm ca làm việc mới"
                    : "Chỉnh sửa ca làm việc",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: template?["name"],
                decoration: const InputDecoration(
                  labelText: "Tên ca làm việc",
                  hintText: "VD: Ca Sáng",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: template != null
                          ? template["timeRange"].split(" - ")[0]
                          : "08:00",
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Giờ bắt đầu",
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 8, minute: 0),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: template != null
                          ? template["timeRange"].split(" - ")[1]
                          : "12:00",
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Giờ kết thúc",
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 0),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: template != null
                    ? template["multiplier"].replaceAll("x", "")
                    : "1.0",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Hệ số tính công",
                  hintText: "1.0",
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Lưu ca làm việc"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text("Cấu hình ca chuẩn"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEditModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _templates.length,
          itemBuilder: (context, index) {
            final template = _templates[index];
            return _buildTemplateCard(template);
          },
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template["name"],
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      template["timeRange"],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template["durationInfo"],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Hệ số lương: ${template["multiplier"]}",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: template["isActive"],
                  onChanged: (val) {
                    setState(() {
                      template["isActive"] = val;
                    });
                  },
                  activeThumbColor: AppTheme.primaryBlue,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () =>
                      _showCreateEditModal(context, template: template),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
