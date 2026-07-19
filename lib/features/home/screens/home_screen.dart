import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../user_management/screens/system_admin_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user?.roleName == 'System Admin' ||
        user?.roleName == 'SystemAdmin') {
      return const SystemAdminDashboard();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: const AppDrawer(),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Chào mừng, ${user?.fullName ?? 'Khách'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vai trò: ${user?.roleName ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Quick Access Grid/List
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (user?.roleName.contains('Store Staff') == true ||
                        user?.roleName.contains('StoreStaff') == true) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/pos');
                        },
                        icon: const Icon(
                          Icons.point_of_sale,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Máy tính tiền (POS)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        context.go('/products');
                      },
                      icon: const Icon(Icons.warehouse, color: Colors.white),
                      label: const Text(
                        'Quản lý sản phẩm',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (user?.roleName == 'Chain Director') ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/categories');
                        },
                        icon: const Icon(Icons.inventory, color: Colors.white),
                        label: const Text(
                          'Quản lý danh mục',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/suppliers');
                        },
                        icon: const Icon(Icons.business, color: Colors.white),
                        label: const Text(
                          'Quản lý nhà cung cấp',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/branches');
                        },
                        icon: const Icon(Icons.storefront, color: Colors.white),
                        label: const Text(
                          'Quản lý chi nhánh',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (user?.roleName.contains('Store Manager') == true ||
                        user?.roleName.contains('StoreManager') == true) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/employee-management');
                        },
                        icon: const Icon(Icons.people, color: Colors.white),
                        label: const Text(
                          'Quản lý nhân viên',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade600,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/store-schedule');
                        },
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Xếp lịch làm việc',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade600,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/attendance-report');
                        },
                        icon: const Icon(Icons.timer, color: Colors.white),
                        label: const Text(
                          'Chấm công nhân viên',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (user?.roleName.contains('Store Staff') == true ||
                        user?.roleName.contains('StoreStaff') == true ||
                        user?.roleName.contains('Warehouse Staff') == true ||
                        user?.roleName.contains('WarehouseStaff') == true) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/personal-schedule');
                        },
                        icon: const Icon(
                          Icons.event_available,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Lịch cá nhân',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (user?.roleName.contains('Store Staff') == true ||
                        user?.roleName.contains('StoreStaff') == true ||
                        user?.roleName.contains('Warehouse Staff') == true ||
                        user?.roleName.contains('WarehouseStaff') == true) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/clock-in');
                        },
                        icon: const Icon(
                          Icons.access_time,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Chấm công (Check-in/out)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
