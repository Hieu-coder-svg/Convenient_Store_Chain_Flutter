import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user.dart';
import 'user_form_screen.dart';
import 'dart:async';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  Timer? _debounce;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers(page: 1);
    });
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

  void _showUserActionSheet(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Thao tác: ${user.fullName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Cập nhật thông tin / Phân quyền'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserFormScreen(user: user),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.orange),
                title: const Text('Đặt lại mật khẩu'),
                onTap: () async {
                  Navigator.pop(context);
                  _handleResetPassword(user);
                },
              ),
              if (user.isActive)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Khóa tài khoản'),
                  onTap: () async {
                    Navigator.pop(context);
                    final provider = context.read<UserProvider>();
                    final success = await provider.deactivateUser(user.userId);
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Khóa tài khoản thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Đã xảy ra lỗi'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  title: const Text('Kích hoạt tài khoản'),
                  onTap: () async {
                    Navigator.pop(context);
                    final provider = context.read<UserProvider>();
                    final success = await provider.activateUser(user.userId);
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kích hoạt tài khoản thành công'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Đã xảy ra lỗi'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa tài khoản'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc chắn muốn xóa tài khoản ${user.fullName}?\n\nLưu ý: Nếu người này đã có dữ liệu liên quan (chấm công, hóa đơn...), hệ thống sẽ chặn xóa. Lúc đó bạn chỉ có thể Khóa tài khoản.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<UserProvider>();
              final success = await provider.deleteUser(user.userId);
              if (!mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa tài khoản thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? 'Đã xảy ra lỗi'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleResetPassword(User user) async {
    final provider = context.read<UserProvider>();
    final newPassword = await provider.resetPassword(user.userId);

    if (!mounted) return;

    if (newPassword != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Đã đặt lại mật khẩu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mật khẩu mới của ${user.fullName} là:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      newPassword,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    // In a real app, add a copy to clipboard button here
                    const Icon(Icons.copy, size: 20, color: Colors.blue),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng copy và gửi mật khẩu này cho người dùng. Mật khẩu này sẽ không hiển thị lại.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } else if (provider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = provider.users;

          return RefreshIndicator(
            onRefresh: () => provider.loadUsers(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.grey),
                              hintText: 'Tìm kiếm theo tên, email...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats Grid (Mock Data for now as per template)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: [
                            _buildStatCard(
                              'TỔNG NHÂN SỰ',
                              '${provider.stats?.totalUsers ?? '-'}',
                              Colors.blue,
                              null,
                            ),
                            _buildStatCard(
                              'CỬA HÀNG TRƯỞNG',
                              '${provider.stats?.storeManagers ?? '-'}',
                              Colors.orange,
                              null,
                            ),
                            _buildStatCard(
                              'ĐANG HOẠT ĐỘNG',
                              '${provider.stats?.activeUsers ?? '-'}',
                              Colors.green,
                              null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'NGƯỜI DÙNG',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const Text(
                              'VAI TRÒ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),

                // User List
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = users[index];
                    return _buildUserListItem(context, user);
                  }, childCount: users.length),
                ),

                // Pagination controls
                if (provider.totalPages > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: provider.currentPage > 1
                                ? () => provider.loadUsers(
                                    page: provider.currentPage - 1,
                                  )
                                : null,
                          ),
                          Text(
                            'Trang ${provider.currentPage} / ${provider.totalPages}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed:
                                provider.currentPage < provider.totalPages
                                ? () => provider.loadUsers(
                                    page: provider.currentPage + 1,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ), // Padding for bottom FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserFormScreen()),
          );
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    String? trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trend != null)
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserListItem(BuildContext context, User user) {
    // Determine avatar initials and color
    String initials = '';
    if (user.fullName.isNotEmpty) {
      var parts = user.fullName.split(' ');
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts.last[0]}'.toUpperCase();
      } else {
        initials = parts[0]
            .substring(0, parts[0].length >= 2 ? 2 : 1)
            .toUpperCase();
      }
    } else {
      initials = 'NA';
    }

    Color avatarColor = Colors.grey[300]!;
    if (user.roleName.contains('Giám đốc')) avatarColor = Colors.blue[100]!;
    if (user.roleName.contains('Quản lý')) avatarColor = Colors.orange[100]!;

    Color badgeColor = Colors.grey;
    if (user.roleName.contains('Giám đốc')) badgeColor = Colors.blue;
    if (user.roleName.contains('Quản lý')) badgeColor = Colors.orange;

    return InkWell(
      onTap: () => _showUserActionSheet(context, user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          color: user.isActive ? Colors.white : Colors.grey[100],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 20,
              child: Text(
                initials,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: user.isActive ? Colors.black87 : Colors.grey,
                      decoration: user.isActive
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.roleName.replaceAll(
                  ' ',
                  '\n',
                ), // Just to match the UI style a bit
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
