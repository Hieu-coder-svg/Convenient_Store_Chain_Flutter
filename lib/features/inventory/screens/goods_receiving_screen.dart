import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';

class GoodsReceivingScreen extends StatefulWidget {
  const GoodsReceivingScreen({super.key});

  @override
  State<GoodsReceivingScreen> createState() => _GoodsReceivingScreenState();
}

class _GoodsReceivingScreenState extends State<GoodsReceivingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _poIdController = TextEditingController();
  final _notesController = TextEditingController();
  
  final List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  void _addItem() {
    setState(() {
      _items.add({
        'productId': null,
        'quantityReceived': null,
        'price': null,
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
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất 1 sản phẩm')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = {
        'purchaseOrderId': int.parse(_poIdController.text),
        'notes': _notesController.text,
        'items': _items,
      };

      await context.read<InventoryProvider>().receiveGoods(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhận hàng thành công', style: TextStyle(color: Colors.green))));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString(), style: const TextStyle(color: Colors.red))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Nhập Kho (Goods Receipt)'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _poIdController,
              decoration: const InputDecoration(labelText: 'Mã đơn đặt hàng (Purchase Order ID)'),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 3,
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
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Product ID', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => item['productId'] = int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Số lượng', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => item['quantityReceived'] = int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Giá', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => item['price'] = double.tryParse(v),
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
                  : const Text('Tạo Phiếu Nhận Hàng'),
            )
          ],
        ),
      ),
    );
  }
}
