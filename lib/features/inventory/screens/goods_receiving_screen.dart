import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/inventory_provider.dart';
import '../../product/providers/product_catalog_provider.dart';
import '../../purchase_order/providers/purchase_order_provider.dart';

class GoodsReceivingScreen extends StatefulWidget {
  const GoodsReceivingScreen({super.key});

  @override
  State<GoodsReceivingScreen> createState() => _GoodsReceivingScreenState();
}

class _GoodsReceivingScreenState extends State<GoodsReceivingScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedPoId;
  final _notesController = TextEditingController();
  
  List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ProductCatalogProvider>().products.isEmpty) {
        context.read<ProductCatalogProvider>().fetchProducts();
      }
      if (context.read<PurchaseOrderProvider>().orders.isEmpty) {
        context.read<PurchaseOrderProvider>().fetchOrders();
      }
    });
  }

  void _onPoChanged(int? newPoId) {
    setState(() {
      _selectedPoId = newPoId;
      _items.clear();
      
      if (newPoId != null) {
        final provider = context.read<PurchaseOrderProvider>();
        final order = provider.orders.firstWhere((o) => o.poId == newPoId);
        
        for (var item in order.items) {
          _items.add({
            'productId': item.productId,
            'productName': item.productName,
            'quantityReceived': null,
            'orderedQuantity': item.quantity,
          });
        }
      }
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
        'poId': _selectedPoId ?? 0,
        'notes': _notesController.text,
        'items': _items.map((i) => {
          'productId': i['productId'],
          'quantityReceived': i['quantityReceived'] ?? 0
        }).toList(),
      };

      await context.read<InventoryProvider>().receiveGoods(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhận hàng thành công', style: TextStyle(color: Colors.green))));
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
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
    final pendingOrders = context.watch<PurchaseOrderProvider>().orders.where((o) => o.status == 'Pending').toList();

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
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Chọn Đơn Đặt Hàng (Pending)', isDense: true),
              value: _selectedPoId,
              isExpanded: true,
              items: pendingOrders.map((o) => DropdownMenuItem<int>(
                value: o.poId,
                child: Text('PO #${o.poId} - ${o.supplierName} (${o.items.length} SP)', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: _onPoChanged,
              validator: (v) => v == null ? 'Vui lòng chọn đơn đặt hàng' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text('Danh sách sản phẩm từ Đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_selectedPoId == null)
               const Text('Vui lòng chọn Đơn đặt hàng ở trên để hiển thị sản phẩm', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['productName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('SL đã đặt: ${item['orderedQuantity']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'SL Thực nhận', isDense: true),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => item['quantityReceived'] = int.tryParse(v),
                          validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Nhập SL' : null,
                        ),
                      ),
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
