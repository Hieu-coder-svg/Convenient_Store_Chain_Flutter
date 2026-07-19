import 'package:flutter/material.dart';
import '../../../core/widgets/app_drawer.dart';
import 'users_screen.dart';
import 'roles_screen.dart';
import 'system_config_screen.dart';

class SystemAdminDashboard extends StatefulWidget {
  const SystemAdminDashboard({super.key});

  @override
  State<SystemAdminDashboard> createState() => _SystemAdminDashboardState();
}

class _SystemAdminDashboardState extends State<SystemAdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const UsersScreen(),
    const RolesScreen(),
  ];

  final List<String> _titles = [
    'Quản lý người dùng',
    'Vai trò & Quyền',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: _screens[_currentIndex],

    );
  }
}
