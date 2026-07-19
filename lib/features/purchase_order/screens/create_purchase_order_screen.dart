import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../product/providers/product_catalog_provider.dart';
import '../../supplier/providers/supplier_provider.dart';
import '../providers/purchase_order_provider.dart';

class CreatePurchaseOrderScreen extends StatefulWidget {
  const CreatePurchaseOrderScreen({super.key});

  @override
  State<CreatePurchaseOrderScreen> createState() => _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends State<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedSupplierId;
  final List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ProductCatalogProvider>().products.isEmpty) {
        context.read<ProductCatalogProvider>().fetchProducts();
      }
      if (context.read<SupplierProvider>().suppliers.isEmpty) {
        context.read<SupplierProvider>().fetchSuppliers();
      }
    });
  }

  void _addItem() {
    setState(() {
      _items.add({
        'productId': null,
        'quantity': null,
        'unitPrice': null,
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn nhà cung cấp')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất 1 sản phẩm')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await context.read<PurchaseOrderProvider>().createOrder(_selectedSupplierId!, _items);
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo Đơn đặt hàng thành công!', style: TextStyle(color: Colors.green))));
        context.pop();
      } else {
        final error = context.read<PurchaseOrderProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Có lỗi xảy ra', style: const TextStyle(color: Colors.red))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductCatalogProvider>().products;
    final suppliers = context.watch<SupplierProvider>().suppliers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Đơn Đặt Hàng Mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Nhà cung cấp', isDense: true),
              value: _selectedSupplierId,
              isExpanded: true,
              items: suppliers.map((s) => DropdownMenuItem<int>(
                value: s.supplierId,
                child: Text(s.supplierName, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedSupplierId = v;
                });
              },
              validator: (v) => v == null ? 'Vui lòng chọn NCC' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm SP'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: 'Sản phẩm', isDense: true),
                          value: item['productId'],
                          isExpanded: true,
                          items: products.map((p) => DropdownMenuItem<int>(
                            value: p.productId,
                            child: Text(p.productName, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) {
                            setState(() {
                              item['productId'] = v;
                            });
                          },
                          validator: (v) => v == null ? 'Chọn' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'SL', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => item['quantity'] = int.tryParse(v),
                          validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Giá', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => item['unitPrice'] = double.tryParse(v),
                          validator: (v) => (v == null || v.isEmpty) ? 'Bắt buộc' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(index),
                      )
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Tạo Đơn Hàng'),
            )
          ],
        ),
      ),
    );
  }
}
