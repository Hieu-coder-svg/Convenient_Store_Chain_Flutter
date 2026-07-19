import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../auth/providers/auth_provider.dart';

class ManagerHomeScreen extends StatelessWidget {
  const ManagerHomeScreen({super.key});

  static const _menuItems = <_ManagerMenuItem>[
    _ManagerMenuItem(
      title: 'Nhà cung cấp',
      subtitle: 'Quản lý đối tác cung ứng',
      icon: Icons.business_outlined,
      route: '/suppliers',
      color: Color(0xFF0F766E),
    ),
    _ManagerMenuItem(
      title: 'Chi nhánh',
      subtitle: 'Thông tin cửa hàng',
      icon: Icons.storefront_outlined,
      route: '/branches',
      color: Color(0xFF0369A1),
    ),
    _ManagerMenuItem(
      title: 'Nhân viên',
      subtitle: 'Quản lý nhân sự',
      icon: Icons.people_outline_rounded,
      route: '/employee-management',
      color: Color(0xFF7C3AED),
    ),
    _ManagerMenuItem(
      title: 'Xếp lịch',
      subtitle: 'Sắp xếp lịch làm việc',
      icon: Icons.calendar_month_outlined,
      route: '/store-schedule',
      color: Color(0xFF4F46E5),
    ),
    _ManagerMenuItem(
      title: 'Máy tính tiền',
      subtitle: 'Bán hàng tại quầy',
      icon: Icons.point_of_sale_outlined,
      route: '/pos',
      color: Color(0xFF15803D),
    ),
    _ManagerMenuItem(
      title: 'Đặt hàng nội bộ',
      subtitle: 'Quản lý đơn nhập hàng',
      icon: Icons.local_shipping_outlined,
      route: '/branch-orders',
      color: Color(0xFFC2410C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'Quản lý cửa hàng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .2),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          _initialOf(user?.fullName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào,',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.fullName ?? 'Quản lý cửa hàng',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Store Manager',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Chức năng quản lý',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ManagerMenuCard(
                    item: _menuItems[index],
                    onTap: () => context.go(_menuItems[index].route),
                  ),
                  childCount: _menuItems.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.08,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialOf(String? name) {
    final value = name?.trim();
    return value == null || value.isEmpty ? 'M' : value[0].toUpperCase();
  }
}

class _ManagerMenuCard extends StatelessWidget {
  const _ManagerMenuCard({required this.item, required this.onTap});

  final _ManagerMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7ECF3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 25),
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagerMenuItem {
  const _ManagerMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}
