import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  String? _selectedPurchaseOrderCode;
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ProductCatalogProvider>().products.isEmpty) {
        context.read<ProductCatalogProvider>().fetchProducts();
      }
      if (context.read<PurchaseOrderProvider>().pendingOrders.isEmpty) {
        context.read<PurchaseOrderProvider>().fetchAllPendingOrders();
      }
    });
  }

  Future<void> _onPoChanged(int? newPoId) async {
    if (newPoId == null) {
      setState(() {
        _selectedPoId = null;
        _selectedPurchaseOrderCode = null;
        _items.clear();
      });
      return;
    }

    final order = await context.read<PurchaseOrderProvider>().fetchOrderById(
      newPoId,
    );
    if (!mounted || order == null) return;

    setState(() {
      _selectedPoId = newPoId;
      _selectedPurchaseOrderCode = order.purchaseOrderCode;
      _items.clear();

      for (var item in order.items) {
        _items.add({
          'productId': item.productId,
          'productName': item.productName,
          'quantityReceived': null,
          'orderedQuantity': item.quantity,
        });
      }
    });
  }

  Future<bool> _confirmReceipt() async {
    final shortages = _items.where((item) {
      final received = item['quantityReceived'] as int? ?? 0;
      final ordered = item['orderedQuantity'] as int;
      return received < ordered;
    }).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          shortages.isEmpty
              ? 'Xác nhận nhận đủ hàng'
              : 'Xác nhận giao hàng thiếu',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shortages.isEmpty)
                const Text(
                  'Số lượng thực nhận bằng số lượng đã đặt. PO sẽ được đóng sau khi xác nhận.',
                )
              else ...[
                const Text(
                  'Một số sản phẩm được nhận ít hơn số lượng Giám đốc chuỗi đã đặt:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...shortages.map((item) {
                  final ordered = item['orderedQuantity'] as int;
                  final received = item['quantityReceived'] as int? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• ${item['productName']}: đặt $ordered, nhận $received, thiếu ${ordered - received}',
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Text(
                  'PO sẽ được đóng sau lần nhận này và không thể nhận bổ sung trên cùng PO. '
                  'Giám đốc chuỗi sẽ nhận thông báo để làm việc với nhà cung cấp hoặc tạo PO bổ sung.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận nhận hàng'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _showReceiptResult(Map<String, dynamic> result) async {
    final items = (result['items'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final hasShortage = result['hasShortage'] == true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(hasShortage ? 'Đã nhận hàng thiếu' : 'Đã nhận đủ hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedPurchaseOrderCode ?? 'Đơn đặt hàng'} đã chuyển sang trạng thái Đã nhận hàng.',
              ),
              const SizedBox(height: 12),
              ...items.map((item) {
                final shortage = item['shortageQuantity'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${item['productName']}: đặt ${item['orderedQuantity']}, '
                    'nhận ${item['quantityReceived']}'
                    '${shortage > 0 ? ', thiếu $shortage' : ''}',
                  ),
                );
              }),
              if (hasShortage) ...[
                const SizedBox(height: 8),
                const Text(
                  'Giám đốc chuỗi đã được thông báo về phần hàng giao thiếu.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 sản phẩm')),
      );
      return;
    }
    if (_items.every((item) => (item['quantityReceived'] as int? ?? 0) == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phải có ít nhất một sản phẩm thực nhận lớn hơn 0.'),
        ),
      );
      return;
    }

    if (!await _confirmReceipt()) return;
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    final inventoryProvider = context.read<InventoryProvider>();
    final purchaseOrderProvider = context.read<PurchaseOrderProvider>();

    try {
      final request = {
        'poId': _selectedPoId ?? 0,
        'notes': _notesController.text,
        'items': _items
            .map(
              (i) => {
                'productId': i['productId'],
                'quantityReceived': i['quantityReceived'] ?? 0,
              },
            )
            .toList(),
      };

      final result = await inventoryProvider.receiveGoods(request);
      await purchaseOrderProvider.fetchAllPendingOrders();

      if (mounted) {
        await _showReceiptResult(result);
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
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
    final pendingOrders = context.watch<PurchaseOrderProvider>().pendingOrders;

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
        title: const Text('Nhập hàng vào kho'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Chọn đơn đặt hàng đang chờ nhận',
                isDense: true,
              ),
              initialValue: _selectedPoId,
              isExpanded: true,
              items: pendingOrders
                  .map(
                    (o) => DropdownMenuItem<int>(
                      value: o.poId,
                      child: Text(
                        '${o.purchaseOrderCode} - ${o.supplierName}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
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
            if (_selectedPoId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Nhập số lượng thực tế nhận được. Có thể nhận ít hơn số lượng đặt, '
                  'nhưng PO sẽ được đóng sau lần nhận này. Nếu giao thiếu, Giám đốc chuỗi '
                  'sẽ nhận thông báo để xử lý với nhà cung cấp.',
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Danh sách sản phẩm từ Đơn hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedPoId == null)
              const Text(
                'Vui lòng chọn Đơn đặt hàng ở trên để hiển thị sản phẩm',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),

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
                            Text(
                              item['productName'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SL đã đặt: ${item['orderedQuantity']} (Thùng)',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            if (item['quantityReceived'] != null)
                              Text(
                                'Chênh lệch: ${(item['quantityReceived'] as int) - (item['orderedQuantity'] as int)}',
                                style: TextStyle(
                                  color:
                                      (item['quantityReceived'] as int) <
                                          (item['orderedQuantity'] as int)
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'SL Thực nhận (Thùng)',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            setState(() {
                              item['quantityReceived'] = int.tryParse(v);
                            });
                          },
                          validator: (v) {
                            final received = int.tryParse(v ?? '');
                            final ordered = item['orderedQuantity'] as int;
                            if (received == null || received < 0) {
                              return 'Phải ≥ 0';
                            }
                            if (received > ordered) return 'Vượt SL đặt';
                            return null;
                          },
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
            ),
          ],
        ),
      ),
    );
  }
}
