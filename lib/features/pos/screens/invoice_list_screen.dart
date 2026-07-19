import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/invoice_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../branch/providers/branch_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _branchId;
  bool _canFilterBranch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        if (user.roleName.toLowerCase().contains('director') ||
            user.roleName.toLowerCase().contains('admin')) {
          _branchId = null;
          _canFilterBranch = true;
          context.read<BranchProvider>().fetchBranches();
        } else {
          _branchId = user.branchId;
          _canFilterBranch = false;
        }
      }
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<InvoiceProvider>().fetchInvoices(
      branchId: _branchId,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Lịch sử hóa đơn',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _fetchData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filter section
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text(
                        'Chi nhánh: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: _canFilterBranch
                            ? Consumer<BranchProvider>(
                                builder: (context, branchProvider, child) {
                                  if (branchProvider.isLoading) {
                                    return const Text('Đang tải...');
                                  }
                                  return DropdownButton<int?>(
                                    isExpanded: true,
                                    value: _branchId,
                                    hint: const Text('Tất cả'),
                                    underline: const SizedBox(),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Tất cả'),
                                      ),
                                      ...branchProvider.branches.map(
                                        (b) => DropdownMenuItem<int?>(
                                          value: b.branchId,
                                          child: Text(
                                            b.isActive
                                                ? b.branchName
                                                : '${b.branchName} (Ngưng hoạt động)',
                                            style: TextStyle(
                                              color: b.isActive
                                                  ? null
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _branchId = val;
                                      });
                                    },
                                  );
                                },
                              )
                            : Text(
                                _branchId != null ? 'CN $_branchId' : 'Tất cả',
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Từ ngày',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                            ),
                            child: Text(
                              _fromDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                                  : 'Chọn ngày',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Đến ngày',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                            ),
                            child: Text(
                              _toDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_toDate!)
                                  : 'Chọn ngày',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _fetchData,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text(
                        'LỌC HÓA ĐƠN',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List section
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                ? Center(
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : provider.invoices.isEmpty
                ? const Center(child: Text('Không có hóa đơn nào.'))
                : ListView.builder(
                    itemCount: provider.invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = provider.invoices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          onTap: () =>
                              context.push('/invoices/${invoice.invoiceId}'),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            'INV-${invoice.invoiceId.toString().padLeft(6, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(dateFormatter.format(invoice.invoiceDate)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    invoice.paymentMethod == 'Cash'
                                        ? Icons.money
                                        : Icons.credit_card,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(invoice.paymentMethod),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormatter.format(invoice.finalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: invoice.status == 'Completed'
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  invoice.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: invoice.status == 'Completed'
                                        ? Colors.green[800]
                                        : Colors.orange[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
