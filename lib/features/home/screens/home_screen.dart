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

    if (user?.roleName.contains('Admin') == true || user?.roleName.contains('Director') == true) {
      return const SystemAdminDashboard();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    if (user?.roleName.contains('Store Manager') == true || user?.roleName.contains('Store Staff') == true || user?.roleName.contains('StoreManager') == true || user?.roleName.contains('StoreStaff') == true) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          context.go('/pos');
                        },
                        icon: const Icon(Icons.point_of_sale, color: Colors.white),
                        label: const Text('Máy tính tiền (POS)', style: TextStyle(color: Colors.white)),
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
                      label: const Text('Quản lý sản phẩm', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        context.go('/categories');
                      },
                      icon: const Icon(Icons.inventory, color: Colors.white),
                      label: const Text('Quản lý danh mục', style: TextStyle(color: Colors.white)),
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
                      label: const Text('Quản lý nhà cung cấp', style: TextStyle(color: Colors.white)),
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
                      label: const Text('Quản lý chi nhánh', style: TextStyle(color: Colors.white)),
                    ),
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
