import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/invoice_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
  double _customerCash = 0;

  @override
  void initState() {
    super.initState();
    _pointsController.addListener(_onPointsChanged);
    _cashController.addListener(_onCashChanged);
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  void _onPointsChanged() {
    final cart = context.read<CartProvider>();
    final customer = context.read<CustomerProvider>().selectedCustomer;
    if (customer == null) return;
    if (customer.loyaltyPoints < 100) {
      // Cannot redeem if points < 100
      _pointsController.text = '0';
      cart.setRedeemPoints(0);
      return;
    }

    int points = int.tryParse(_pointsController.text) ?? 0;
    if (points > customer.loyaltyPoints) {
      points = customer.loyaltyPoints;
      _pointsController.text = points.toString();
      _pointsController.selection = TextSelection.fromPosition(TextPosition(offset: _pointsController.text.length));
    }
    
    // Convert points to discount (1 point = 100 VND)
    // Discount cannot exceed subtotal
    double maxDiscount = cart.subtotal;
    int maxPoints = (maxDiscount / 100).ceil();
    if (points > maxPoints) {
      points = maxPoints;
      _pointsController.text = points.toString();
      _pointsController.selection = TextSelection.fromPosition(TextPosition(offset: _pointsController.text.length));
    }

    cart.setRedeemPoints(points);
  }

  void _onCashChanged() {
    setState(() {
      _customerCash = double.tryParse(_cashController.text.replaceAll(',', '')) ?? 0;
    });
  }

  Future<void> _handleCheckout() async {
    final cart = context.read<CartProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final authProvider = context.read<AuthProvider>();

    // Set branch id from current logged-in user
    // AuthResponse currently doesn't provide branchId, defaulting to 1 for testing
    if (authProvider.currentUser != null) {
      cart.setBranchId(1);
    }

    final payload = cart.toCheckoutPayload(customerProvider.selectedCustomer?.customerId);

    final success = await invoiceProvider.checkout(payload);

    if (!mounted) return;

    if (success) {
      cart.clearCart();
      customerProvider.clearSelectedCustomer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green),
      );
      // Navigate to receipt screen
      context.go('/invoices/${invoiceProvider.lastCreatedInvoice!.invoiceId}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(invoiceProvider.error ?? 'Thanh toán thất bại'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final invoiceProvider = context.watch<InvoiceProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final double change = _customerCash - cart.grandTotal;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Xác nhận thanh toán'),
      ),
      body: invoiceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order Summary
                  _buildSectionTitle('Tóm tắt đơn hàng'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSummaryRow('Số mặt hàng', '${cart.totalItems} SP'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Tổng số lượng', '${cart.totalQuantity}'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Tổng tiền hàng', currencyFormatter.format(cart.subtotal)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer & Points
                  _buildSectionTitle('Khách hàng'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: customerProvider.selectedCustomer == null
                          ? Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  // Open dialog from POS screen logic or just navigate back
                                  context.pop(); 
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khách hàng ở màn hình trước.')));
                                },
                                icon: const Icon(Icons.person_search),
                                label: const Text('Quay lại chọn khách hàng'),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      customerProvider.selectedCustomer!.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('⭐ Điểm hiện có: ${customerProvider.selectedCustomer!.loyaltyPoints} điểm'),
                                const SizedBox(height: 16),
                                const Text('Đổi điểm (1 điểm = 100đ):'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _pointsController,
                                  keyboardType: TextInputType.number,
                                  enabled: customerProvider.selectedCustomer!.loyaltyPoints >= 100,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    hintText: customerProvider.selectedCustomer!.loyaltyPoints >= 100 
                                      ? 'Nhập số điểm...' 
                                      : 'Cần tối thiểu 100 điểm để đổi',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '→ Giảm giá: -${currencyFormatter.format(cart.discountFromPoints)}',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  _buildSectionTitle('Phương thức thanh toán'),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile(
                          title: const Text('💵 Tiền mặt'),
                          value: 'Cash',
                          groupValue: cart.paymentMethod,
                          onChanged: (val) => cart.setPaymentMethod(val.toString()),
                        ),
                        RadioListTile(
                          title: const Text('💳 Thẻ (Card)'),
                          value: 'Card',
                          groupValue: cart.paymentMethod,
                          onChanged: (val) => cart.setPaymentMethod(val.toString()),
                        ),
                        RadioListTile(
                          title: const Text('📱 Chuyển khoản (QR)'),
                          value: 'QR',
                          groupValue: cart.paymentMethod,
                          onChanged: (val) => cart.setPaymentMethod(val.toString()),
                        ),
                      ],
                    ),
                  ),

                  // Cash input if Cash is selected
                  if (cart.paymentMethod == 'Cash') ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tiền khách đưa:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _cashController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                                suffixText: 'đ',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('💰 Tiền thối lại:'),
                                Text(
                                  change >= 0 ? currencyFormatter.format(change) : 'Chưa đủ',
                                  style: TextStyle(
                                    color: change >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    )
                  ],

                  const SizedBox(height: 24),
                  // Grand Total
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildSummaryRow('Tổng tiền hàng:', currencyFormatter.format(cart.subtotal)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Giảm giá (${cart.redeemPoints} điểm):', '-${currencyFormatter.format(cart.discountFromPoints)}'),
                        const Divider(thickness: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TỔNG THANH TOÁN:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              currencyFormatter.format(cart.grandTotal),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: (cart.paymentMethod == 'Cash' && change < 0) ? null : _handleCheckout,
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
