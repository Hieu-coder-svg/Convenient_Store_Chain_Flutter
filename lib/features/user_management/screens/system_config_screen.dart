import 'package:flutter/material.dart';

class SystemConfigScreen extends StatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  State<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends State<SystemConfigScreen> {
  // Sales & Loyalty State
  final TextEditingController _vatCtrl = TextEditingController(text: '8');
  final TextEditingController _loyaltyRateCtrl = TextEditingController(
    text: '10000',
  );

  // HR State
  TimeOfDay _morningStart = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _morningEnd = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _afternoonStart = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _afternoonEnd = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _nightStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _nightEnd = const TimeOfDay(hour: 6, minute: 0);
  final TextEditingController _lateLimitCtrl = TextEditingController(
    text: '10',
  );

  // Inventory & Alerts State
  final TextEditingController _warehouseThresholdCtrl = TextEditingController(
    text: '50',
  );
  final TextEditingController _branchThresholdCtrl = TextEditingController(
    text: '10',
  );
  bool _emailAlertEnabled = true;

  // Security State
  final bool _twoFactorEnabled = false;

  bool _isSaving = false;

  @override
  void dispose() {
    _vatCtrl.dispose();
    _loyaltyRateCtrl.dispose();
    _lateLimitCtrl.dispose();
    _warehouseThresholdCtrl.dispose();
    _branchThresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onSelected,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _handleSave() async {
    setState(() => _isSaving = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Đã lưu cấu hình thành công!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.point_of_sale, 'Bán hàng & Khách hàng'),
            _buildCard([
              _buildNumberInputRow(
                'Thuế VAT mặc định (%)',
                _vatCtrl,
                suffix: '%',
              ),
              const Divider(),
              _buildNumberInputRow(
                'Tỷ lệ quy đổi điểm (VNĐ/Điểm)',
                _loyaltyRateCtrl,
                suffix: 'VNĐ = 1 Điểm',
                width: 100,
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader(Icons.access_time, 'Ca làm việc & Nhân sự'),
            _buildCard([
              _buildTimeRangeRow('Ca Sáng', _morningStart, _morningEnd, (
                start,
                end,
              ) {
                setState(() {
                  _morningStart = start;
                  _morningEnd = end;
                });
              }),
              const Divider(),
              _buildTimeRangeRow('Ca Chiều', _afternoonStart, _afternoonEnd, (
                start,
                end,
              ) {
                setState(() {
                  _afternoonStart = start;
                  _afternoonEnd = end;
                });
              }),
              const Divider(),
              _buildTimeRangeRow('Ca Đêm', _nightStart, _nightEnd, (
                start,
                end,
              ) {
                setState(() {
                  _nightStart = start;
                  _nightEnd = end;
                });
              }),
              const Divider(),
              _buildNumberInputRow(
                'Giới hạn đi trễ (Phút)',
                _lateLimitCtrl,
                suffix: 'Phút',
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader(Icons.inventory_2, 'Kho & Cảnh báo'),
            _buildCard([
              _buildNumberInputRow(
                'Ngưỡng cảnh báo Kho Tổng',
                _warehouseThresholdCtrl,
                suffix: 'SP',
              ),
              const Divider(),
              _buildNumberInputRow(
                'Ngưỡng cảnh báo Chi Nhánh',
                _branchThresholdCtrl,
                suffix: 'SP',
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Gửi thông báo qua Email',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Tự động gửi báo cáo khi tồn kho thấp',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: _emailAlertEnabled,
                activeThumbColor: Colors.blue,
                onChanged: (val) => setState(() => _emailAlertEnabled = val),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader(Icons.security, 'Bảo mật'),
            _buildCard([
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Yêu cầu xác thực 2 lớp (2FA)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Tăng cường bảo mật bằng mã OTP. (Tính năng sắp ra mắt)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: _twoFactorEnabled,
                onChanged: null, // Disabled
              ),
            ]),

            const SizedBox(height: 80), // Padding for Bottom button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving ? 'Đang lưu...' : 'Lưu cấu hình',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildNumberInputRow(
    String label,
    TextEditingController controller, {
    String? suffix,
    double width = 60,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: width,
                height: 36,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 8),
                Text(
                  suffix,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeRow(
    String label,
    TimeOfDay start,
    TimeOfDay end,
    Function(TimeOfDay, TimeOfDay) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          Row(
            children: [
              InkWell(
                onTap: () => _selectTime(
                  context,
                  start,
                  (newStart) => onChanged(newStart, end),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _formatTime(start),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('-', style: TextStyle(color: Colors.grey)),
              ),
              InkWell(
                onTap: () => _selectTime(
                  context,
                  end,
                  (newEnd) => onChanged(start, newEnd),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _formatTime(end),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
