import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

import '../models/branch_inventory_model.dart';
import '../providers/inventory_provider.dart';

class _AdjustmentEntry {
  final BranchInventoryModel inventory;
  final TextEditingController actualController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  String reason = 'Other';

  _AdjustmentEntry(this.inventory);

  int? get actualQuantity => int.tryParse(actualController.text);
  int? get delta => actualQuantity == null
      ? null
      : actualQuantity! - inventory.quantity;

  void dispose() {
    actualController.dispose();
    noteController.dispose();
  }
}

class StockAdjustmentScreen extends StatefulWidget {
  final int branchId;

  const StockAdjustmentScreen({super.key, required this.branchId});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_AdjustmentEntry> _entries = [];
  bool _isSubmitting = false;

  static const _reasonLabels = {
    'Damaged': 'Hư hỏng',
    'Expired': 'Hết hạn',
    'Lost': 'Mất mát',
    'Found': 'Tìm thấy hàng thừa',
    'Other': 'Khác',
  };

  static const _reasonDescriptions = {
    'Damaged': 'Sản phẩm bị hư hỏng và đã được trừ khỏi tồn kho.',
    'Expired': 'Sản phẩm đã hết hạn và đã được trừ khỏi tồn kho.',
    'Lost': 'Phát hiện thiếu hoặc mất hàng so với số liệu hệ thống.',
    'Found': 'Phát hiện hàng thừa và đã được cộng vào tồn kho.',
    'Other': 'Có chênh lệch tồn kho với nguyên nhân khác.',
  };

  Color _reasonColor(String reason) => switch (reason) {
        'Damaged' || 'Expired' || 'Lost' => Colors.red,
        'Found' => Colors.green,
        _ => Colors.orange,
      };

  IconData _reasonIcon(String reason) => switch (reason) {
        'Damaged' => Icons.broken_image_outlined,
        'Expired' => Icons.event_busy_outlined,
        'Lost' => Icons.report_problem_outlined,
        'Found' => Icons.add_circle_outline,
        _ => Icons.info_outline,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<InventoryProvider>()
          .fetchAllBranchInventoryForAdjustment(widget.branchId);
    });
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addInventory(BranchInventoryModel inventory) {
    final existing = _entries.indexWhere(
      (entry) => entry.inventory.productId == inventory.productId,
    );
    if (existing >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${inventory.productName} đã có trong danh sách.')),
      );
      return;
    }
    setState(() => _entries.add(_AdjustmentEntry(inventory)));
  }

  Future<void> _scanBarcode() async {
    try {
      final barcode = await SimpleBarcodeScanner.scanBarcode(
        context,
        barcodeAppBar: const BarcodeAppBar(
          appBarTitle: 'Quét mã vạch sản phẩm',
          centerTitle: true,
          enableBackButton: true,
        ),
        isShowFlashIcon: true,
        scanFormat: ScanFormat.ONLY_BARCODE,
      );
      if (!mounted || barcode == null || barcode.isEmpty || barcode == '-1') {
        return;
      }
      final inventoryItems =
          context.read<InventoryProvider>().adjustmentBranchItems;
      BranchInventoryModel? match;
      for (final item in inventoryItems) {
        if (item.barcode?.trim() == barcode.trim()) {
          match = item;
          break;
        }
      }
      if (match == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không tìm thấy mã $barcode trong tồn kho chi nhánh này.',
            ),
          ),
        );
      } else {
        _addInventory(match);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thiết bị không mở được camera quét mã vạch. Bạn vẫn có thể tìm sản phẩm thủ công. ($error)',
          ),
        ),
      );
    }
  }

  Future<void> _showProductPicker() async {
    final items = context.read<InventoryProvider>().adjustmentBranchItems;
    var keyword = '';
    final selected = await showModalBottomSheet<BranchInventoryModel>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = items.where((item) {
            final search = keyword.toLowerCase();
            return item.productName.toLowerCase().contains(search) ||
                (item.barcode?.toLowerCase().contains(search) ?? false);
          }).toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Tìm tên hoặc mã vạch',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          setSheetState(() => keyword = value),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(item.productName),
                          subtitle: Text(
                            'Hệ thống: ${item.quantity} ${item.unit ?? ''} • Mã: ${item.barcode ?? 'Chưa có'}',
                          ),
                          onTap: () => Navigator.pop(sheetContext, item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected != null) _addInventory(selected);
  }

  List<String> _allowedReasons(_AdjustmentEntry entry) {
    final delta = entry.delta;
    if (delta == null || delta == 0) return const ['Other'];
    return delta < 0
        ? const ['Damaged', 'Expired', 'Lost', 'Other']
        : const ['Found', 'Other'];
  }

  void _onActualChanged(_AdjustmentEntry entry) {
    final allowed = _allowedReasons(entry);
    setState(() {
      if (!allowed.contains(entry.reason)) entry.reason = 'Other';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất một sản phẩm.')),
      );
      return;
    }
    final changedEntries =
        _entries.where((entry) => entry.delta != null && entry.delta != 0).toList();
    if (changedEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có chênh lệch tồn kho để cập nhật.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận kết quả kiểm kê'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: changedEntries
                .map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.inventory.productName),
                    subtitle: Text(
                      '${entry.inventory.quantity} → ${entry.actualQuantity} ${entry.inventory.unit ?? ''}\n'
                      'Chênh lệch: ${entry.delta! > 0 ? '+' : ''}${entry.delta} • ${_reasonLabels[entry.reason]}'
                      '${entry.noteController.text.trim().isEmpty ? '' : '\nGhi chú: ${entry.noteController.text.trim()}'}',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kiểm tra lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận cập nhật'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await context.read<InventoryProvider>().adjustStock(
            widget.branchId,
            changedEntries
                .map(
                  (entry) => {
                    'productId': entry.inventory.productId,
                    'expectedQuantity': entry.inventory.quantity,
                    'actualQuantity': entry.actualQuantity,
                    'reason': entry.reason,
                    'note': entry.noteController.text.trim().isEmpty
                        ? null
                        : entry.noteController.text.trim(),
                  },
                )
                .toList(),
          );
      if (!mounted) return;
      await _showResult(result);
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showResult(Map<String, dynamic> result) {
    final adjustedItems = result['adjustedItems'] as List? ?? const [];
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kiểm kê thành công'),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...adjustedItems.map((raw) {
                final item = Map<String, dynamic>.from(raw as Map);
                final delta = item['delta'] as int? ?? 0;
                final reason = item['reason']?.toString() ?? 'Other';
                final reasonLabel = _reasonLabels[reason] ?? reason;
                final note = item['note']?.toString().trim();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _reasonIcon(reason),
                    color: _reasonColor(reason),
                  ),
                  title: Text(item['productName']?.toString() ?? ''),
                  subtitle: Text(
                    '${item['oldQuantity']} → ${item['actualQuantity']} • '
                    'Chênh lệch: ${delta > 0 ? '+' : ''}$delta\n'
                    'Tình trạng: $reasonLabel\n'
                    '${_reasonDescriptions[reason] ?? _reasonDescriptions['Other']}'
                    '${note == null || note.isEmpty ? '' : '\nGhi chú: $note'}',
                  ),
                );
              }),
              const Divider(),
              Text(
                'Tổng chênh lệch: ${result['totalDelta'] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm kê kho chi nhánh')),
      body: provider.isLoadingAdjustmentItems
          ? const Center(child: CircularProgressIndicator())
          : provider.branchError != null &&
                  provider.adjustmentBranchItems.isEmpty
              ? Center(child: Text(provider.branchError!))
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showProductPicker,
                                icon: const Icon(Icons.search),
                                label: const Text('Tìm sản phẩm'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Quét mã vạch'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _entries.isEmpty
                            ? const Center(
                                child: Text(
                                  'Quét mã vạch hoặc tìm sản phẩm để bắt đầu kiểm kê.',
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _entries.length,
                                itemBuilder: (context, index) =>
                                    _buildEntryCard(index, _entries[index]),
                              ),
                      ),
                      SafeArea(
                        minimum: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Hoàn tất kiểm kê'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEntryCard(int index, _AdjustmentEntry entry) {
    final delta = entry.delta;
    final allowedReasons = _allowedReasons(entry);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.inventory.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa',
                  onPressed: () {
                    setState(() {
                      final removed = _entries.removeAt(index);
                      removed.dispose();
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            Text(
              'Mã vạch: ${entry.inventory.barcode ?? 'Chưa có'} • '
              'Hệ thống: ${entry.inventory.quantity} ${entry.inventory.unit ?? ''}',
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.actualController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số lượng thực tế (${entry.inventory.unit ?? 'đơn vị'})',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _onActualChanged(entry),
                    validator: (value) {
                      final actual = int.tryParse(value ?? '');
                      if (actual == null) return 'Vui lòng nhập số nguyên';
                      if (actual < 0) return 'Không được nhập số âm';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('${entry.inventory.productId}-${entry.reason}-${delta ?? 'none'}'),
                    initialValue: entry.reason,
                    decoration: const InputDecoration(
                      labelText: 'Lý do',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: allowedReasons
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(_reasonLabels[reason]!),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => entry.reason = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entry.reason == 'Other') ...[
              TextFormField(
                controller: entry.noteController,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú nguyên nhân khác *',
                  hintText: 'Mô tả nguyên nhân chênh lệch tồn kho',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) {
                  if (entry.delta != null &&
                      entry.delta != 0 &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập ghi chú khi chọn lý do Khác';
                  }
                  if ((value?.trim().length ?? 0) > 500) {
                    return 'Ghi chú không được vượt quá 500 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
            ],
            Text(
              delta == null
                  ? 'Chênh lệch: chưa nhập số thực tế'
                  : 'Chênh lệch: ${delta > 0 ? '+' : ''}$delta ${entry.inventory.unit ?? ''}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: delta == null || delta == 0
                    ? Colors.grey
                    : delta < 0
                        ? Colors.red
                        : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
