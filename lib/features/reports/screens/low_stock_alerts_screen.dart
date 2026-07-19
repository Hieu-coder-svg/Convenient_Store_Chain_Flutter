import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/reports_provider.dart';

class LowStockAlertsScreen extends StatefulWidget {
  const LowStockAlertsScreen({Key? key}) : super(key: key);

  @override
  _LowStockAlertsScreenState createState() => _LowStockAlertsScreenState();
}

class _LowStockAlertsScreenState extends State<LowStockAlertsScreen> {
  final TextEditingController _warehouseThresholdCtrl = TextEditingController();
  final TextEditingController _branchThresholdCtrl = TextEditingController();
  bool _isLoadingConfig = true;
  bool _isSavingConfig = false;
  final DioClient _dioClient = DioClient();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchLowStockAlerts();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final response = await _dioClient.dio.get('/SystemSettings');
      final List<dynamic> data = response.data;
      
      for (var item in data) {
        if (item['settingKey'] == 'WarehouseLowStockThreshold') {
          _warehouseThresholdCtrl.text = item['settingValue'];
        } else if (item['settingKey'] == 'BranchLowStockThreshold') {
          _branchThresholdCtrl.text = item['settingValue'];
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải cấu hình: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConfig = false;
        });
      }
    }
  }

  void _handleSaveConfig() async {
    setState(() => _isSavingConfig = true);
    try {
      final settings = {
        'WarehouseLowStockThreshold': _warehouseThresholdCtrl.text,
        'BranchLowStockThreshold': _branchThresholdCtrl.text,
      };
      await _dioClient.dio.put('/SystemSettings', data: settings);
      
      if (mounted) {
        setState(() => _isSavingConfig = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu cấu hình ngưỡng cảnh báo thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh alerts with new thresholds
        context.read<ReportsProvider>().fetchLowStockAlerts();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingConfig = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu cấu hình: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _warehouseThresholdCtrl.dispose();
    _branchThresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Cảnh Báo Hàng Sắp Hết'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ReportsProvider>().fetchLowStockAlerts();
            },
          ),
        ],
      ),
      body: Consumer<ReportsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingAlerts) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${provider.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchLowStockAlerts(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final alerts = provider.lowStockAlerts;
          final user = context.watch<AuthProvider>().currentUser;
          final isDirector = user?.roleName.contains('Director') == true || user?.roleName == 'SystemAdmin';
          
          Widget configWidget = const SizedBox.shrink();
          if (isDirector) {
            configWidget = _buildThresholdConfig();
          }

          if (alerts == null || alerts.isEmpty) {
            return Column(
              children: [
                configWidget,
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green[400], size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Không có mặt hàng nào sắp hết.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              configWidget,
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
              final alert = alerts[index];
              final isCritical = alert.currentStock == 0;
              
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCritical ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isCritical ? Colors.red[50] : Colors.orange[50],
                    child: Icon(
                      isCritical ? Icons.warning : Icons.inventory_2_outlined,
                      color: isCritical ? Colors.red : Colors.orange,
                    ),
                  ),
                  title: Text(
                    alert.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Danh mục: ${alert.categoryName}'),
                      const SizedBox(height: 2),
                      Text(
                        'Vị trí: ${alert.locationName} (${alert.locationType})',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tồn: ${alert.currentStock}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCritical ? Colors.red : Colors.orange,
                        ),
                      ),
                      Text(
                        'Định mức: ${alert.minimumThreshold}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  },
),
    );
  }

  Widget _buildThresholdConfig() {
    if (_isLoadingConfig) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cấu hình ngưỡng cảnh báo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _warehouseThresholdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ngưỡng Kho Tổng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _branchThresholdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ngưỡng Chi Nhánh',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSavingConfig ? null : _handleSaveConfig,
                  icon: _isSavingConfig
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Lưu'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
