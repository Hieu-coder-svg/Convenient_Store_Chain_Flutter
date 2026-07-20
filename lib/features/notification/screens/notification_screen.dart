import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/notification_provider.dart';
import '../../purchase_order/providers/purchase_order_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      context.read<NotificationProvider>().startSignalR();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData({bool refresh = false}) {
    if (refresh) {
      _currentPage = 1;
    }
    context.read<NotificationProvider>().fetchNotifications(page: _currentPage);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<NotificationProvider>();
      if (!provider.isLoading &&
          provider.notifications.length < provider.totalCount) {
        _currentPage++;
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Thông Báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: () {
              context.read<NotificationProvider>().markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(refresh: true),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && _currentPage == 1) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return const Center(child: Text('Không có thông báo nào.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              itemCount:
                  provider.notifications.length + (provider.isLoading ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == provider.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = provider.notifications[index];

                return ListTile(
                  tileColor: item.isRead
                      ? Colors.transparent
                      : Colors.blue.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    backgroundColor: item.isRead
                        ? Colors.grey
                        : AppColors.primary,
                    child: Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(item.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(item.createdAt.toLocal()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: item.purchaseOrderId == null
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    if (!item.isRead) {
                      await provider.markAsRead(item.notificationId);
                    }
                    if (!context.mounted) return;
                    final poId = item.purchaseOrderId;
                    if (poId != null) {
                      final order = await context
                          .read<PurchaseOrderProvider>()
                          .fetchOrderById(poId);
                      if (!context.mounted) return;
                      if (order != null) {
                        context.push('/purchase-orders/$poId');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Không thể tải chi tiết đơn đặt hàng.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
