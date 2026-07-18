import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/invoice_provider.dart';
import '../models/invoice_model.dart';
import '../widgets/receipt_view.dart';
import '../../../../core/constants/app_colors.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  InvoiceModel? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvoice();
    });
  }

  Future<void> _loadInvoice() async {
    final provider = context.read<InvoiceProvider>();
    final invoice = await provider.getInvoiceById(widget.invoiceId);
    
    if (mounted) {
      setState(() {
        _invoice = invoice;
        _isLoading = false;
        _error = provider.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _invoice != null ? 'Hóa đơn #INV-${_invoice!.invoiceId.toString().padLeft(6, '0')}' : 'Chi tiết hóa đơn',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/invoices');
            }
          },
        ),
        actions: [
          if (_invoice != null)
            IconButton(
              icon: const Icon(Icons.print, color: AppColors.textSecondary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang gửi lệnh in đến máy in...')),
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _invoice != null ? _buildBottomActions(context) : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _invoice == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Không tìm thấy hóa đơn', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoice,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ReceiptView(invoice: _invoice!),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement actual printing via ESC/POS or Bluetooth printer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang gửi lệnh in đến máy in...')),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('IN HÓA ĐƠN'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/pos');
                },
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text('ĐƠN MỚI', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
