import 'package:flutter/material.dart';
import '../models/user.dart';

class UserFormScreen extends StatefulWidget {
  final User? user; // Nếu null => Create, Nếu có => Update

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

  int _selectedRoleId = 3; // Mặc định Store Staff (tùy theo logic DB)
  
  final List<Map<String, dynamic>> _roles = [
    {'id': 1, 'name': 'System Admin'},
    {'id': 2, 'name': 'Store Manager'},
    {'id': 3, 'name': 'Store Staff'},
  ];

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user?.username ?? '');
    _fullNameCtrl = TextEditingController(text: widget.user?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
    _passwordCtrl = TextEditingController();
    
    if (widget.user != null) {
      _selectedRoleId = widget.user!.roleId;
    }
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
    
    // TODO: Call Create/Update API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng Lưu đang được hoàn thiện')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.user != null;

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
              _buildSectionTitle('Thông tin cơ bản'),
              _buildTextField(
                controller: _usernameCtrl,
                label: 'Tên đăng nhập',
                enabled: !isUpdate, // Không cho sửa username
                validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
              ),
              _buildTextField(
                controller: _fullNameCtrl,
                label: 'Họ và tên',
                validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập email';
                  if (!val.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Số điện thoại',
                keyboardType: TextInputType.phone,
              ),

              if (!isUpdate) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Mật khẩu'),
                _buildTextField(
                  controller: _passwordCtrl,
                  label: 'Mật khẩu',
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (val.length < 8) return 'Mật khẩu tối thiểu 8 ký tự';
                    // Theo BR-15: Chữ hoa, số, ký tự đặc biệt
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(val)) return 'Phải chứa ít nhất 1 chữ hoa';
                    if (!RegExp(r'(?=.*[0-9])').hasMatch(val)) return 'Phải chứa ít nhất 1 chữ số';
                    if (!RegExp(r'(?=.*[!@#\$&*~])').hasMatch(val)) return 'Phải chứa ít nhất 1 ký tự đặc biệt';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              _buildSectionTitle('Vai trò & Chi nhánh'),
              DropdownButtonFormField<int>(
                initialValue: _selectedRoleId,
                decoration: InputDecoration(
                  labelText: 'Vai trò',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem<int>(
                    value: role['id'],
                    child: Text(role['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRoleId = val!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: null,
                decoration: InputDecoration(
                  labelText: 'Chi nhánh (Tùy chọn)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem<int>(value: 1, child: Text('Chi nhánh Quận 1')),
                  DropdownMenuItem<int>(value: 2, child: Text('Chi nhánh Quận 3')),
                ],
                onChanged: (val) {},
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isUpdate ? 'Lưu thay đổi' : 'Tạo tài khoản',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
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
  }

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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[200],
        ),
      ),
    );
  }
}
