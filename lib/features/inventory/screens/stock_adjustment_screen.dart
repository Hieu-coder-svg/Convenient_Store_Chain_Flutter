import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import '../../product/providers/product_catalog_provider.dart';

class StockAdjustmentScreen extends StatefulWidget {
  final int? branchId;
  const StockAdjustmentScreen({super.key, this.branchId});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  final List<String> _reasons = ['Damaged', 'Expired', 'Lost', 'Found', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ProductCatalogProvider>().products.isEmpty) {
        context.read<ProductCatalogProvider>().fetchProducts();
      }
    });
  }

  void _addItem() {
    setState(() {
      _items.add({
        'productId': null,
        'actualQuantity': null,
        'reason': 'Other',
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất 1 sản phẩm để kiểm kê')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.branchId == null) {
        await context.read<InventoryProvider>().adjustWarehouseStock(_items);
      } else {
        await context.read<InventoryProvider>().adjustStock(widget.branchId!, _items);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kiểm kê thành công', style: TextStyle(color: Colors.green))));
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
    final products = context.watch<ProductCatalogProvider>().products;
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
        title: Text(widget.branchId == null ? 'Kiểm Kê Kho Tổng' : 'Kiểm Kê Kho Chi Nhánh'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Danh sách kiểm kê', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
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
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'SL Thực tế', isDense: true),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => item['actualQuantity'] = int.tryParse(v),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Lý do', isDense: true),
                        value: item['reason'],
                        items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (v) {
                          setState(() {
                            item['reason'] = v;
                          });
                        },
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
                  : const Text('Hoàn Tất Kiểm Kê'),
            )
          ],
        ),
      ),
    );
  }
}
