import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../product/providers/product_catalog_provider.dart';
import '../../supplier/providers/supplier_provider.dart';
import '../providers/purchase_order_provider.dart';

class CreatePurchaseOrderScreen extends StatefulWidget {
  final int? initialSupplierId;
  final List<Map<String, dynamic>>? initialItems;

  const CreatePurchaseOrderScreen({
    super.key,
    this.initialSupplierId,
    this.initialItems,
  });

  @override
  State<CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState extends State<CreatePurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedSupplierId;
  final List<Map<String, dynamic>> _items = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedSupplierId = widget.initialSupplierId;
    _items.addAll(
      (widget.initialItems ?? const <Map<String, dynamic>>[]).map(
        Map<String, dynamic>.from,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductCatalogProvider>().fetchPurchaseOrderProducts();
      context.read<SupplierProvider>().fetchPurchaseOrderSuppliers();
    });
  }

  void _addItem() {
    setState(() {
      _items.add({'productId': null, 'quantity': null, 'unitPrice': null});
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhà cung cấp')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 sản phẩm')),
      );
      return;
    }

    final productIds = _items.map((item) => item['productId'] as int).toList();
    if (productIds.toSet().length != productIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không được chọn trùng sản phẩm')),
      );
      return;
    }

    // PO quantities and prices are expressed in the product's import unit.
    // The backend converts received import units into base inventory units once.
    final submitItems = _items.map((item) {
      return {
        'productId': item['productId'],
        'quantity': item['quantity'],
        'unitPrice': item['unitPrice'],
      };
    }).toList();

    setState(() {
      _isSubmitting = true;
    });

    final success = await context.read<PurchaseOrderProvider>().createOrder(
      _selectedSupplierId!,
      submitItems,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tạo Đơn đặt hàng thành công!',
              style: TextStyle(color: Colors.green),
            ),
          ),
        );
        context.pop();
      } else {
        final error = context.read<PurchaseOrderProvider>().error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'Có lỗi xảy ra',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductCatalogProvider>();
    final supplierProvider = context.watch<SupplierProvider>();
    final products = productProvider.purchaseOrderProducts;
    final suppliers = supplierProvider.purchaseOrderSuppliers;
    final isLoadingOptions =
        productProvider.isLoadingPurchaseOrderProducts ||
        supplierProvider.isLoadingPurchaseOrderSuppliers;
    final optionsError =
        productProvider.purchaseOrderProductsError ??
        supplierProvider.purchaseOrderSuppliersError;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.initialItems?.isEmpty ?? true)
              ? 'Tạo đơn đặt hàng mới'
              : 'Tạo đơn bổ sung',
        ),
      ),
      body: isLoadingOptions
          ? const Center(child: CircularProgressIndicator())
          : optionsError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(optionsError, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        productProvider.fetchPurchaseOrderProducts(
                          forceRefresh: true,
                        );
                        supplierProvider.fetchPurchaseOrderSuppliers(
                          forceRefresh: true,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử tải lại'),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.initialItems?.isNotEmpty ?? false) ...[
                    const Card(
                      color: Color(0xFFFFF3E0),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Đơn được điền sẵn theo số lượng giao thiếu. Giám đốc chuỗi có thể '
                          'điều chỉnh trước khi gửi đơn mới cho nhà cung cấp.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Nhà cung cấp',
                      isDense: true,
                    ),
                    initialValue: _selectedSupplierId,
                    isExpanded: true,
                    items: suppliers
                        .map(
                          (s) => DropdownMenuItem<int>(
                            value: s.supplierId,
                            child: Text(
                              s.supplierName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
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
                      const Text(
                        'Danh sách sản phẩm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                                decoration: const InputDecoration(
                                  labelText: 'Sản phẩm',
                                  isDense: true,
                                ),
                                initialValue: item['productId'],
                                isExpanded: true,
                                items: products
                                    .map(
                                      (p) => DropdownMenuItem<int>(
                                        value: p.productId,
                                        child: Text(
                                          '${p.productName} (${p.importUnit ?? "Thùng"} - ${p.conversionFactor} ${p.unit ?? "cái"})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
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
                                initialValue: item['quantity']?.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'SL nhập',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) =>
                                    item['quantity'] = int.tryParse(v),
                                validator: (v) {
                                  final quantity = int.tryParse(v ?? '');
                                  if (quantity == null || quantity <= 0) {
                                    return 'Phải > 0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: item['unitPrice']?.toString(),
                                decoration: const InputDecoration(
                                  labelText: 'Giá/đơn vị nhập',
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (v) =>
                                    item['unitPrice'] = double.tryParse(v),
                                validator: (v) {
                                  final price = double.tryParse(v ?? '');
                                  if (price == null || price < 0) {
                                    return 'Không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
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
                        : const Text('Tạo Đơn Hàng'),
                  ),
                ],
              ),
            ),
    );
  }
}
