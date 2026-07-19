import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../providers/reports_provider.dart';
import '../models/supplier_performance_dto.dart';

class SupplierPerformanceScreen extends StatefulWidget {
  const SupplierPerformanceScreen({super.key});

  @override
  State<SupplierPerformanceScreen> createState() => _SupplierPerformanceScreenState();
}

class _SupplierPerformanceScreenState extends State<SupplierPerformanceScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<ReportsProvider>().fetchSupplierPerformance(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Đánh giá Nhà cung cấp', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: AppColors.primary),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingSupplierPerformance) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.error != null) {
            return Center(child: Text('Lỗi: ${provider.error}', style: const TextStyle(color: Colors.red)));
          }

          final suppliers = provider.supplierPerformanceList;

          if (suppliers.isEmpty) {
            return const Center(child: Text('Không có dữ liệu nhà cung cấp trong khoảng thời gian này'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: suppliers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return _buildSupplierCard(supplier, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildSupplierCard(SupplierPerformanceDto supplier, int rank) {
    final performanceColor = supplier.deliveryPerformancePercentage >= 80 
        ? Colors.green 
        : supplier.deliveryPerformancePercentage >= 50 
            ? Colors.orange 
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text('#$rank', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  supplier.supplierName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Text(
                currencyFormat.format(supplier.totalValueProvided),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Tổng đơn hàng', supplier.totalOrders.toString(), Icons.shopping_cart, Colors.blue),
              _buildStatItem('Giao đúng hạn', supplier.onTimeDeliveries.toString(), Icons.check_circle, Colors.green),
              _buildStatItem('Giao trễ hạn', supplier.lateDeliveries.toString(), Icons.cancel, Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Tỷ lệ đúng hạn: ', style: TextStyle(color: AppColors.textSecondary)),
              Expanded(
                child: LinearProgressIndicator(
                  value: supplier.totalOrders > 0 ? supplier.onTimeDeliveries / supplier.totalOrders : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(performanceColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${supplier.deliveryPerformancePercentage.toStringAsFixed(1)}%',
                style: TextStyle(fontWeight: FontWeight.bold, color: performanceColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }
}
