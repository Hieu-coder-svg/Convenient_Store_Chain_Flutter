import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'user_form_screen.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  Timer? _debounce;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final auth = authProvider.currentUser;

    if (auth == null) {
      debugPrint("Auth user chưa sẵn sàng.");
      return;
    }

    // Logic phân quyền: Manager lấy theo chi nhánh, Admin/Director lấy tất cả (null)
    final isManager = auth.roleName.contains('Manager');
    final int? branchIdToLoad = isManager ? auth.branchId : null;

    debugPrint("Khởi tạo danh sách nhân viên với branchId: $branchIdToLoad");
    userProvider.loadUsers(
      branchId: branchIdToLoad,
      page: 1,
      requireBranch: isManager,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<UserProvider>().setSearchTerm(query);
    });
  }

  void _navigateToUserForm([User? user]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserFormScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserInfo = authProvider.currentUser;
    final String initial = currentUserInfo?.fullName.isNotEmpty == true
        ? currentUserInfo!.fullName.substring(0, 1).toUpperCase()
        : "U";

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text("Quản lý nhân viên"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentAmber,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                _buildSearchBar(),
                _buildKpiSummary(provider),
                Expanded(
                  child: provider.isLoading && provider.users.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () async {
                            final auth = context
                                .read<AuthProvider>()
                                .currentUser;
                            final isManager =
                                auth?.roleName.contains('Manager') == true;
                            final branchId = isManager ? auth?.branchId : null;
                            await provider.loadUsers(
                              branchId: branchId,
                              page: 1,
                              requireBranch: isManager,
                            );
                          },
                          child: _buildEmployeeList(provider),
                        ),
                ),
                if (provider.totalPages > 1) _buildPagination(provider),
              ],
            );
          },
        ),
      ),
      floatingActionButton: currentUserInfo?.roleName == 'Store Manager'
          ? null
          : FloatingActionButton(
              onPressed: () => _navigateToUserForm(),
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: "Tìm kiếm theo tên, email...",
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildKpiSummary(UserProvider provider) {
    final stats = provider.stats;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildKpiCard(
            "Tổng nhân sự",
            "${stats?.totalUsers ?? '-'}",
            valueColor: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          _buildKpiCard(
            "Đang hoạt động",
            "${stats?.activeUsers ?? '-'}",
            valueColor: AppTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: valueColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList(UserProvider provider) {
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Lỗi: ${provider.error}",
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (provider.users.isEmpty && !provider.isLoading) {
      return const Center(child: Text("Không tìm thấy nhân viên nào."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: provider.users.length,
      itemBuilder: (context, index) {
        final emp = provider.users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${emp.username} • ${emp.email}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (emp.branchName != null)
                        Text(
                          "🏠 ${emp.branchName}",
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  onPressed: () => _navigateToUserForm(emp),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(UserProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.currentPage > 1
                ? () => provider.loadUsers(page: provider.currentPage - 1)
                : null,
          ),
          Text(
            'Trang ${provider.currentPage} / ${provider.totalPages}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.currentPage < provider.totalPages
                ? () => provider.loadUsers(page: provider.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
