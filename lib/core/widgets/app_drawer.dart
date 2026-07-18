import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Bảng điều khiển',
                  onTap: () => context.go('/home'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'Thông tin cá nhân',
                  onTap: () {
                    // TODO: Implement Profile Screen
                    Navigator.pop(context); // Close drawer
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/notifications');
                  },
                ),
                const Divider(),

                // Cửa hàng & Sản phẩm
                _buildSectionTitle('CỬA HÀNG & SẢN PHẨM'),
                _buildNavItem(
                  context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Sản phẩm',
                  onTap: () => context.go('/products'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.category_outlined,
                  title: 'Danh mục',
                  onTap: () => context.go('/categories'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.warehouse_outlined,
                  title: 'Kho tổng (Warehouse)',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/warehouse-inventory');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Kho chi nhánh (Branch)',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/branch-inventory');
                  },
                ),
                

                // Đối tác & Chi nhánh
                _buildSectionTitle('ĐỐI TÁC & CHI NHÁNH'),
                _buildNavItem(
                  context,
                  icon: Icons.business_outlined,
                  title: 'Nhà cung cấp',
                  onTap: () => context.go('/suppliers'),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.storefront_outlined,
                  title: 'Chi nhánh',
                  onTap: () => context.go('/branches'),
                ),

                // NHÂN SỰ & CA LÀM
                _buildSectionTitle('NHÂN SỰ & CA LÀM'),
                if (user?.roleName.contains('Admin') == true ||
                    user?.roleName.contains('Director') == true ||
                    user?.roleName.contains('Store Manager') == true ||
                    user?.roleName.contains('StoreManager') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.people_outline,
                    title: 'Quản lý nhân viên',
                    onTap: () => context.go('/employee-management'),
                  ),
                if (user?.roleName.contains('Admin') == true ||
                    user?.roleName.contains('Director') == true ||
                    user?.roleName.contains('Store Manager') == true ||
                    user?.roleName.contains('StoreManager') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: 'Xếp lịch làm việc',
                    onTap: () => context.go('/store-schedule'),
                  ),
                if (user?.roleName.contains('Admin') == true ||
                    user?.roleName.contains('Director') == true ||
                    user?.roleName.contains('Store Manager') == true ||
                    user?.roleName.contains('StoreManager') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.timer_outlined,
                    title: 'Chấm công nhân viên',
                    onTap: () => context.go('/attendance-report'),
                  ),
                if (user?.roleName.contains('Admin') == true ||
                    user?.roleName.contains('Director') == true ||
                    user?.roleName.contains('Store Manager') == true ||
                    user?.roleName.contains('StoreManager') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.schedule_outlined,
                    title: 'Mẫu ca làm việc',
                    onTap: () => context.go('/shift-templates'),
                  ),
                if (user?.roleName.contains('Store Staff') == true ||
                    user?.roleName.contains('StoreStaff') == true ||
                    user?.roleName.contains('Warehouse Staff') == true ||
                    user?.roleName.contains('WarehouseStaff') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.event_available_outlined,
                    title: 'Lịch cá nhân',
                    onTap: () => context.go('/personal-schedule'),
                  ),
                if (user?.roleName.contains('Store Staff') == true ||
                    user?.roleName.contains('StoreStaff') == true ||
                    user?.roleName.contains('Warehouse Staff') == true ||
                    user?.roleName.contains('WarehouseStaff') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.access_time,
                    title: 'Chấm công (Check-in/out)',
                    onTap: () => context.go('/clock-in'),
                  ),

                // Nghiệp vụ (Branch Orders & POS)
                _buildSectionTitle('NGHIỆP VỤ'),
                if (user?.roleName.contains('Store Manager') == true ||
                    user?.roleName.contains('Store Staff') == true ||
                    user?.roleName.contains('StoreManager') == true ||
                    user?.roleName.contains('StoreStaff') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.point_of_sale,
                    title: 'Máy tính tiền (POS)',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      context.go('/pos');
                    },
                  ),
                _buildNavItem(
                  context,
                  icon: Icons.local_shipping_outlined,
                  title: 'Đơn đặt hàng nội bộ',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    context.go('/branch-orders');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.add_box_outlined,
                  title: 'Nhận hàng (Goods Receipt)',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/goods-receiving');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Lịch sử hóa đơn',
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    context.go('/invoices');
                  },
                ),
                if (user?.roleName.contains('Director') == true || user?.roleName.contains('Admin') == true || user?.roleName.contains('Store Manager') == true || user?.roleName.contains('StoreManager') == true)
                  _buildNavItem(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Báo cáo doanh thu',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      context.go('/daily-summary');
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Logout Button at the bottom
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Navigator.pop(context); // Close drawer first
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF1E88E5), // Darker blue
          ],
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      accountName: Text(
        user?.fullName ?? 'Người dùng',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      accountEmail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user?.username ?? 'Chưa đăng nhập'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user?.roleName ?? 'N/A',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      margin: EdgeInsets.zero,
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
