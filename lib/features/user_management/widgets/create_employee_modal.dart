import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CreateEmployeeModal extends StatefulWidget {
  const CreateEmployeeModal({Key? key}) : super(key: key);

  @override
  State<CreateEmployeeModal> createState() => _CreateEmployeeModalState();
}

class _CreateEmployeeModalState extends State<CreateEmployeeModal> {
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Thêm nhân viên mới"),
        actions: [
          TextButton(
            onPressed: () {
              // Save logic
              Navigator.of(context).pop();
            },
            child: const Text(
              "Lưu",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarUploadZone(),
              const SizedBox(height: 24),
              _buildSectionTitle("Thông tin cá nhân"),
              const SizedBox(height: 12),
              _buildTextField("Họ và tên", TextInputType.name),
              const SizedBox(height: 16),
              _buildTextField("Số điện thoại", TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField("Email", TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField("Số CCCD / CMND", TextInputType.number),
              const SizedBox(height: 24),
              _buildSectionTitle("Phân công công việc"),
              const SizedBox(height: 12),
              _buildDropdownField("Cửa hàng làm việc", [
                "WinMart+ #104",
                "WinMart+ #205",
                "Kho Tổng",
              ]),
              const SizedBox(height: 16),
              _buildDropdownField("Vai trò hệ thống", [
                "Quản lý",
                "Thu ngân",
                "Kho",
                "Bảo vệ",
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle("Cấu hình tài khoản"),
              const SizedBox(height: 12),
              _buildTextField(
                "Mã nhân viên",
                TextInputType.text,
                initialValue: "NV2026-999",
                readOnly: true,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  "Trạng thái hoạt động",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                value: _isActive,
                onChanged: (val) {
                  setState(() {
                    _isActive = val;
                  });
                },
                activeColor: AppTheme.successGreen,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarUploadZone() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(
              Icons.camera_alt,
              size: 32,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tải ảnh đại diện",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildTextField(
    String label,
    TextInputType keyboardType, {
    String? initialValue,
    bool readOnly = false,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: (value) {},
    );
  }
}
