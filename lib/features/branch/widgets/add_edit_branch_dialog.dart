import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/branch_model.dart';
import '../providers/branch_provider.dart';

class AddEditBranchDialog extends StatefulWidget {
  final BranchModel? branch;

  const AddEditBranchDialog({super.key, this.branch});

  @override
  State<AddEditBranchDialog> createState() => _AddEditBranchDialogState();
}

class _AddEditBranchDialogState extends State<AddEditBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.branch?.branchName);
    _phoneController = TextEditingController(text: widget.branch?.phone);
    _addressController = TextEditingController(text: widget.branch?.address);
    _isActive = widget.branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    final branch = BranchModel(
      branchId: widget.branch?.branchId ?? 0,
      branchName: name,
      phone: phone.isEmpty ? null : phone,
      address: address.isEmpty ? null : address,
      isActive: _isActive,
    );

    final provider = context.read<BranchProvider>();
    bool success;
    if (widget.branch == null) {
      success = await provider.addBranch(branch);
    } else {
      success = await provider.editBranch(branch);
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.branch == null
                ? 'Đã thêm chi nhánh thành công'
                : 'Đã cập nhật chi nhánh thành công',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Thao tác thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.branch == null ? 'Thêm chi nhánh mới' : 'Chỉnh sửa chi nhánh',
      ),
      content: _isSaving
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên chi nhánh *',
                          hintText: 'Cửa hàng tiện lợi Q1',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tên chi nhánh không được để trống';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          hintText: '028 XXXX XXXX',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ chi nhánh',
                          hintText: '123 Lê Lợi, Bến Nghé, Quận 1...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Active switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trạng thái hoạt động (Active)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() => _isActive = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: _isSaving
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: _saveBranch,
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
    );
  }
}
