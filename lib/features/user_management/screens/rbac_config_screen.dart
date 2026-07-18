import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RbacConfigScreen extends StatefulWidget {
  const RbacConfigScreen({Key? key}) : super(key: key);

  @override
  State<RbacConfigScreen> createState() => _RbacConfigScreenState();
}

class _RbacConfigScreenState extends State<RbacConfigScreen> {
  String _selectedRole = "Quản lý cửa hàng";

  final List<String> _roles = [
    "Giám đốc chuỗi",
    "Quản lý cửa hàng",
    "Nhân viên bán hàng",
  ];

  final List<Map<String, dynamic>> _permissions = [
    {
      "title": "Xem báo cáo",
      "subtitle": "Xem doanh thu, lợi nhuận, chi phí",
      "isChecked": true,
    },
    {
      "title": "Quản lý nhân sự",
      "subtitle": "Chấm công, xếp lịch, hồ sơ NV",
      "isChecked": true,
    },
    {
      "title": "Quản lý kho",
      "subtitle": "Nhập hàng, kiểm kho, điều chuyển",
      "isChecked": true,
    },
    {
      "title": "Cấu hình hệ thống",
      "subtitle": "Thay đổi thông số, kết nối API",
      "isChecked": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vai trò & Quyền hạn")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoBanner(),
                    _buildRoleSelector(),
                    _buildPermissionsList(),
                  ],
                ),
              ),
            ),
            _buildStickyActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Việc thay đổi quyền hạn sẽ áp dụng ngay lập tức cho tất cả người dùng thuộc vai trò này. Vui lòng kiểm tra kỹ trước khi lưu.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chọn vai trò", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _roles.map((role) {
                final isSelected = role == _selectedRole;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRole = role;
                        });
                      }
                    },
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Danh sách quyền hạn",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ..._permissions.map((perm) => _buildPermissionCard(perm)).toList(),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(Map<String, dynamic> perm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: CheckboxListTile(
        value: perm["isChecked"],
        onChanged: (val) {
          setState(() {
            perm["isChecked"] = val ?? false;
          });
        },
        title: Text(
          perm["title"],
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          perm["subtitle"],
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        activeColor: AppTheme.primaryBlue,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildStickyActionBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                "24 Tài khoản đang áp dụng vai trò này",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text("Lưu thay đổi")),
        ],
      ),
    );
  }
}
