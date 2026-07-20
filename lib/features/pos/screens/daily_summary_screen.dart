import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/invoice_provider.dart';
import '../models/daily_summary_model.dart';
import '../models/period_summary_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../branch/providers/branch_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  int? _branchId;
  bool _canFilterBranch = false;
  
  DailySummaryModel? _dailySummary;
  PeriodSummaryModel? _periodSummary;
  
  bool _isFetching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        if (user.roleName.toLowerCase().contains('director') ||
            user.roleName.toLowerCase().contains('admin')) {
          _branchId = 1;
          _canFilterBranch = true;
          context.read<BranchProvider>().fetchBranches().then((_) {
            final branches = context.read<BranchProvider>().branches;
            if (branches.isNotEmpty && _branchId == null) {
              setState(() {
                _branchId = branches.first.branchId;
              });
            }
          });
        } else {
          _branchId = user.branchId;
          _canFilterBranch = false;
        }
      }
      if (_branchId != null) {
        _fetchSummary();
      }
    });
  }

  Future<void> _fetchSummary() async {
    if (_branchId == null) return;

    setState(() {
      _isFetching = true;
      _error = null;
    });

    final isSingleDay = _selectedDateRange.start.isAtSameMomentAs(_selectedDateRange.end) || 
                        _selectedDateRange.start.difference(_selectedDateRange.end).inDays == 0;

    if (isSingleDay) {
      final summary = await context.read<InvoiceProvider>().fetchDailySummary(
        branchId: _branchId!,
        date: _selectedDateRange.start,
      );
      if (mounted) {
        setState(() {
          _dailySummary = summary;
          _periodSummary = null;
          _isFetching = false;
          _error = context.read<InvoiceProvider>().error;
        });
      }
    } else {
      final summary = await context.read<InvoiceProvider>().fetchPeriodSummary(
        branchId: _branchId!,
        startDate: _selectedDateRange.start,
        endDate: _selectedDateRange.end,
      );
      if (mounted) {
        setState(() {
          _periodSummary = summary;
          _dailySummary = null;
          _isFetching = false;
          _error = context.read<InvoiceProvider>().error;
        });
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Báo cáo doanh thu',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actions: [
          if (_periodSummary != null)
            IconButton(
              icon: const Icon(Icons.print, color: AppColors.primary),
              tooltip: 'Xem bản in',
              onPressed: () => _showPrintDialog(context),
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
                                    hint: const Text('Chọn chi nhánh'),
                                    underline: const SizedBox(),
                                    items: branchProvider.branches
                                        .map(
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
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _branchId = val;
                                      });
                                    },
                                  );
                                },
                              )
                            : Text(
                                _branchId != null
                                    ? 'CN $_branchId'
                                    : 'Không xác định',
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ngày: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDateRange(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedDateRange.start.isAtSameMomentAs(_selectedDateRange.end) || _selectedDateRange.start.difference(_selectedDateRange.end).inDays == 0
                                  ? DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)
                                  : '${DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.end)}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_branchId == null || _isFetching)
                          ? null
                          : _fetchSummary,
                      icon: _isFetching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.bar_chart, color: Colors.white),
                      label: const Text(
                        'XEM BÁO CÁO',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Result section
          Expanded(child: _buildResult()),
        ],
      ),
    );
  }

  bool get _hasData => _dailySummary != null || _periodSummary != null;
  int get _totalInvoices => _periodSummary?.totalInvoices ?? _dailySummary?.totalInvoices ?? 0;
  double get _totalRevenue => _periodSummary?.totalRevenue ?? _dailySummary?.totalRevenue ?? 0;
  double get _totalDiscount => _periodSummary?.totalDiscount ?? _dailySummary?.totalDiscount ?? 0;
  double get _netRevenue => _periodSummary?.netRevenue ?? _dailySummary?.netRevenue ?? 0;

  Widget _buildResult() {
    if (_isFetching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasData) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu báo cáo',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isSingleDay = _selectedDateRange.start.isAtSameMomentAs(_selectedDateRange.end) || _selectedDateRange.start.difference(_selectedDateRange.end).inDays == 0;
    final reportTitle = isSingleDay
        ? 'BÁO CÁO NGÀY ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)}'
        : 'BÁO CÁO TỪ ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)} ĐẾN ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.end)}';

    return RefreshIndicator(
      onRefresh: _fetchSummary,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_chart,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Chi nhánh: CN $_branchId'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                title: 'Tổng hóa đơn',
                value: '$_totalInvoices',
                unit: 'đơn',
                icon: Icons.receipt_long,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Doanh thu',
                value: formatCurrency
                    .format(_totalRevenue)
                    .replaceAll(' đ', ''),
                unit: 'VNĐ',
                icon: Icons.monetization_on,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Giảm giá',
                value: formatCurrency
                    .format(_totalDiscount)
                    .replaceAll(' đ', ''),
                unit: 'VNĐ',
                icon: Icons.local_offer,
                color: Colors.red,
              ),
              _buildStatCard(
                title: 'Doanh thu ròng',
                value: formatCurrency
                    .format(_netRevenue)
                    .replaceAll(' đ', ''),
                unit: 'VNĐ',
                icon: Icons.trending_up,
                color: Colors.green,
                isHighlight: true,
              ),
            ],
          ),
          if (_periodSummary != null && _periodSummary!.dailyRecords.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Biểu đồ doanh thu ròng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildChart() {
    final records = _periodSummary!.dailyRecords;
    if (records.isEmpty) return const SizedBox();

    double maxRevenue = 0;
    for (var r in records) {
      if (r.netRevenue > maxRevenue) {
        maxRevenue = r.netRevenue;
      }
    }
    
    // Add 10% padding to max for Y axis
    maxRevenue = maxRevenue + (maxRevenue * 0.1);
    if (maxRevenue == 0) maxRevenue = 100000;

    final spots = records.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.netRevenue);
    }).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < records.length) {
                    final date = records[value.toInt()].date;
                    if (date == null) return const Text('');
                    // Show every 2nd or 3rd label if too many days
                    if (records.length > 7 && value.toInt() % 2 != 0 && value.toInt() != records.length - 1) {
                      return const Text('');
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxRevenue > 0 ? maxRevenue / 4 : 1,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('');
                  String text;
                  if (value >= 1000000) {
                    text = '${(value / 1000000).toStringAsFixed(1)}M';
                  } else if (value >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(0)}K';
                  } else {
                    text = value.toStringAsFixed(0);
                  }
                  return Text(
                    text,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: records.length.toDouble() - 1,
          minY: 0,
          maxY: maxRevenue,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueGrey,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
                  return LineTooltipItem(
                    formatCurrency.format(touchedSpot.y),
                    textStyle,
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Card(
      elevation: isHighlight ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighlight
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: isHighlight
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isHighlight ? color : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              unit,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showPrintDialog(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ), // Bill style
          backgroundColor: Colors.grey[100],
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CONVENIENCE STORE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text('Chi nhánh: CN $_branchId'),
                const SizedBox(height: 16),
                const Text(
                  'BÁO CÁO DOANH THU',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDateRange.start.isAtSameMomentAs(_selectedDateRange.end) || _selectedDateRange.start.difference(_selectedDateRange.end).inDays == 0
                    ? 'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)}'
                    : 'Từ: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)} - Đến: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.end)}'
                ),
                const SizedBox(height: 16),
                const Text('----------------------------------------'),
                const SizedBox(height: 16),
                _buildPrintRow(
                  'Tổng số hóa đơn:',
                  '${_periodSummary!.totalInvoices} đơn',
                ),
                const SizedBox(height: 8),
                _buildPrintRow(
                  'Tổng doanh thu:',
                  formatCurrency.format(_periodSummary!.totalRevenue),
                ),
                const SizedBox(height: 8),
                _buildPrintRow(
                  'Tổng giảm giá:',
                  formatCurrency.format(_periodSummary!.totalDiscount),
                ),
                const SizedBox(height: 16),
                const Text('----------------------------------------'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DOANH THU RÒNG:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      formatCurrency.format(_periodSummary!.netRevenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Ngày in:'),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã gửi lệnh in đến máy in...'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'IN BÁO CÁO',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'ĐÓNG',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrintRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
