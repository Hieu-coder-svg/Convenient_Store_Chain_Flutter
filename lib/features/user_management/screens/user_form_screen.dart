import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../../auth/providers/auth_provider.dart';
// Đảm bảo import đúng đường dẫn đến BranchProvider của bạn
import '../../branch/providers/branch_provider.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _passwordCtrl;

  int _selectedRoleId = 3;
  int? _selectedBranchId; // Biến lưu ID chi nhánh được chọn

  final List<Map<String, dynamic>> _roles = [
    {'id': 3, 'name': 'Quản lý cửa hàng'},
    {'id': 4, 'name': 'Nhân viên cửa hàng'},
    {'id': 5, 'name': 'Nhân viên kho'},
  ];

  int _roleIdFor(User user) {
    if (_roles.any((role) => role['id'] == user.roleId)) return user.roleId;

    switch (user.roleName) {
      case 'Store Manager':
        return 3;
      case 'Store Staff':
        return 4;
      case 'Warehouse Staff':
        return 5;
      default:
        return 4;
    }
  }

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user?.username ?? '');
    _fullNameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    _passwordCtrl = TextEditingController();

    if (widget.user != null) {
      _selectedRoleId = _roleIdFor(widget.user!);
      _selectedBranchId = widget.user!.branchId; // Gán ID chi nhánh từ user
    }

    // Tải dữ liệu chi nhánh từ Backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchProvider>().fetchBranches();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isUpdate = widget.user != null;
    final provider = context.read<UserProvider>();

    final data = {
      'fullName': _fullNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'roleId': _selectedRoleId,
      'branchId': _selectedBranchId, // Đã thêm branchId vào đây
    };

    if (!isUpdate) {
      data['username'] = _usernameCtrl.text.trim();
      data['password'] = _passwordCtrl.text;
    } else {
      data['isActive'] = widget.user!.isActive;
    }

    bool success = isUpdate
        ? await provider.updateUser(widget.user!.userId, data)
        : await provider.createUser(data);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate ? 'Cập nhật thành công!' : 'Tạo mới thành công!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Đã xảy ra lỗi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.user != null;
    final isManager =
        context.watch<AuthProvider>().currentUser?.roleName == 'Store Manager';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isUpdate ? 'Cập nhật Người dùng' : 'Thêm Người dùng mới'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... các TextField thông tin cơ bản giữ nguyên ...
              _buildSectionTitle('Thông tin cơ bản'),
              _buildTextField(
                controller: _usernameCtrl,
                label: 'Tên đăng nhập',
                enabled: !isUpdate,
                validator: (value) {
                  if (isUpdate) return null;
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Vui lòng nhập tên đăng nhập.';
                  if (text.length < 3)
                    return 'Tên đăng nhập phải có ít nhất 3 ký tự.';
                  if (text.length > 50)
                    return 'Tên đăng nhập không được quá 50 ký tự.';
                  return null;
                },
              ),
              _buildTextField(
                controller: _fullNameCtrl,
                label: 'Họ và tên',
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Vui lòng nhập họ và tên.'
                    : null,
              ),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final valid = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(text);
                  return valid ? null : 'Email không đúng định dạng.';
                },
              ),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Số điện thoại *',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Vui lòng nhập số điện thoại.';
                  final valid = RegExp(r'^\+?\d{9,12}$').hasMatch(text);
                  return valid ? null : 'Số điện thoại phải gồm 9–12 chữ số.';
                },
              ),

              if (!isUpdate) ...[
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordCtrl,
                  label: 'Mật khẩu',
                  obscureText: true,
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) return 'Vui lòng nhập mật khẩu.';
                    final valid = RegExp(
                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$',
                    ).hasMatch(text);
                    return valid
                        ? null
                        : 'Mật khẩu tối thiểu 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.';
                  },
                ),
              ],

              const SizedBox(height: 16),
              _buildSectionTitle('Vai trò & Chi nhánh'),

              // Dropdown Vai trò
              DropdownButtonFormField<int>(
                value: _selectedRoleId,
                decoration: _inputDecoration('Vai trò'),
                items: _roles.map((role) {
                  return DropdownMenuItem<int>(
                    value: role['id'],
                    child: Text(role['name']),
                  );
                }).toList(),
                onChanged: isManager
                    ? null
                    : (val) => setState(() => _selectedRoleId = val!),
              ),

              const SizedBox(height: 16),

              // Dropdown Chi nhánh (Động)
              Consumer<BranchProvider>(
                builder: (context, branchProvider, _) {
                  return DropdownButtonFormField<int>(
                    value: _selectedBranchId,
                    decoration: _inputDecoration('Chi nhánh (Tùy chọn)'),
                    items: branchProvider.branches.map((branch) {
                      return DropdownMenuItem<int>(
                        value: branch.branchId,
                        child: Text(branch.branchName),
                      );
                    }).toList(),
                    onChanged: isManager
                        ? null
                        : (val) => setState(() => _selectedBranchId = val),
                    hint: branchProvider.isLoading
                        ? const Text("Đang tải...")
                        : null,
                    validator: (value) {
                      if ((_selectedRoleId == 3 || _selectedRoleId == 4) &&
                          value == null) {
                        return 'Vai trò cửa hàng bắt buộc phải chọn chi nhánh.';
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                  ),
                  child: const Text(
                    'Lưu thay đổi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.white,
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: _inputDecoration(
          label,
        ).copyWith(fillColor: enabled ? Colors.white : Colors.grey[200]),
      ),
    );
  }
}
