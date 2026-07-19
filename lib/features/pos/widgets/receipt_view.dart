import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

class ReceiptView extends StatelessWidget {
  final InvoiceModel invoice;

  const ReceiptView({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CONVENIENCE STORE',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Chi nhánh: ${invoice.branchName}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          const _DashedLine(),
          const SizedBox(height: 16),
          _buildInfoRow('Hóa đơn số:', '#${invoice.invoiceId}'),
          _buildInfoRow('Ngày:', dateFormatter.format(invoice.invoiceDate)),
          _buildInfoRow('Thu ngân:', invoice.staffName),
          if (invoice.customerName != null)
            _buildInfoRow('Khách hàng:', invoice.customerName!),
          const SizedBox(height: 16),
          const _DashedLine(),
          const SizedBox(height: 16),

          // Items Header
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'SL',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Thành tiền',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Items List
          ...invoice.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.productName,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      item.quantity.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      currencyFormatter.format(item.subTotal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const _DashedLine(),
          const SizedBox(height: 16),

          // Totals
          _buildTotalRow(
            'Cộng tiền hàng:',
            currencyFormatter.format(invoice.totalAmount),
          ),
          if (invoice.discountAmount > 0)
            _buildTotalRow(
              'Giảm giá (Điểm):',
              '-${currencyFormatter.format(invoice.discountAmount)}',
            ),
          const SizedBox(height: 8),
          _buildTotalRow(
            'TỔNG THANH TOÁN:',
            currencyFormatter.format(invoice.finalAmount),
            isBold: true,
            size: 18,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Hình thức:', invoice.paymentMethod),

          // Points
          if (invoice.loyaltyPointsEarned != null &&
              invoice.loyaltyPointsEarned! > 0) ...[
            const SizedBox(height: 16),
            const _DashedLine(),
            const SizedBox(height: 16),
            const Text(
              'THÔNG TIN ĐIỂM THƯỞNG',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Điểm tích lũy lần này:',
              '+${invoice.loyaltyPointsEarned}',
            ),
            if (invoice.customerLoyaltyBalance != null)
              _buildInfoRow(
                'Tổng điểm hiện có:',
                '${invoice.customerLoyaltyBalance}',
              ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Cảm ơn quý khách và hẹn gặp lại!',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double size = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: size,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: size,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.constrainWidth() / 5).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: 3,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}
