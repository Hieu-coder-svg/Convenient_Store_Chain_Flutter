import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class AddEditSupplierDialog extends StatefulWidget {
  final SupplierModel? supplier;

  const AddEditSupplierDialog({super.key, this.supplier});

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.supplier?.supplierName,
    );
    _contactController = TextEditingController(
      text: widget.supplier?.contactName,
    );
    _phoneController = TextEditingController(text: widget.supplier?.phone);
    _emailController = TextEditingController(text: widget.supplier?.email);
    _addressController = TextEditingController(text: widget.supplier?.address);
    _isActive = widget.supplier?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final address = _addressController.text.trim();

    final supplier = SupplierModel(
      supplierId: widget.supplier?.supplierId ?? 0,
      supplierName: name,
      contactName: contact.isEmpty ? null : contact,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
      address: address.isEmpty ? null : address,
      isActive: _isActive,
    );

    final provider = context.read<SupplierProvider>();
    bool success;
    if (widget.supplier == null) {
      success = await provider.addSupplier(supplier);
    } else {
      success = await provider.editSupplier(supplier);
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.supplier == null
                ? 'Đã thêm nhà cung cấp thành công'
                : 'Đã cập nhật nhà cung cấp thành công',
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
        widget.supplier == null
            ? 'Thêm nhà cung cấp mới'
            : 'Chỉnh sửa nhà cung cấp',
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
                          labelText: 'Tên nhà cung cấp *',
                          hintText: 'Acecook Vietnam',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tên nhà cung cấp không được để trống';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          labelText: 'Người liên hệ',
                          hintText: 'Nguyễn Văn A',
                        ),
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'info@supplier.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ',
                          hintText: 'Số 1, Đường 2, KCN Tân Bình...',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Active switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Đang hợp tác (Active)',
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
                onPressed: _saveSupplier,
                child: const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
    );
  }
}
