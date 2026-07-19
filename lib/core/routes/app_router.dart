import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/product/screens/product_list_screen.dart';
import '../../features/product/screens/category_list_screen.dart';
import '../../features/product/screens/add_edit_product_screen.dart';
import '../../features/supplier/screens/supplier_list_screen.dart';
import '../../features/branch/screens/branch_list_screen.dart';
import '../../features/branch_order/screens/branch_order_list_screen.dart';
import '../../features/branch_order/screens/create_branch_order_screen.dart';
import '../../features/branch_order/screens/branch_order_detail_screen.dart';
import '../../features/pos/screens/pos_screen.dart';
import '../../features/inventory/screens/warehouse_inventory_screen.dart';
import '../../features/inventory/screens/goods_receiving_screen.dart';
import '../../features/inventory/screens/branch_inventory_screen.dart';
import '../../features/inventory/screens/stock_adjustment_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/pos/screens/checkout_screen.dart';
import '../../features/pos/screens/invoice_detail_screen.dart';
import '../../features/pos/screens/invoice_list_screen.dart';
import '../../features/pos/screens/daily_summary_screen.dart';
import '../../features/user_management/screens/employee_management_screen.dart';
import '../../features/user_management/screens/store_schedule_builder_screen.dart';
import '../../features/user_management/screens/personal_schedule_screen.dart';
import '../../features/user_management/screens/clock_in_screen.dart';
import '../../features/user_management/screens/attendance_report_screen.dart';
import '../../features/user_management/screens/work_history_screen.dart';
import '../../features/user_management/screens/shift_templates_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/products/add',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/products/edit/:id',
        builder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return AddEditProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SupplierListScreen(),
      ),
      GoRoute(
        path: '/branches',
        builder: (context, state) => const BranchListScreen(),
      ),
      GoRoute(
        path: '/branch-orders',
        builder: (context, state) => const BranchOrderListScreen(),
      ),
      GoRoute(
        path: '/branch-orders/create',
        builder: (context, state) => const CreateBranchOrderScreen(),
      ),
      GoRoute(
        path: '/branch-orders/:id',
        builder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return BranchOrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(path: '/pos', builder: (context, state) => const PosScreen()),
      GoRoute(
        path: '/warehouse-inventory',
        builder: (context, state) => const WarehouseInventoryScreen(),
      ),
      GoRoute(
        path: '/goods-receiving',
        builder: (context, state) => const GoodsReceivingScreen(),
      ),
      GoRoute(
        path: '/branch-inventory',
        builder: (context, state) => const BranchInventoryScreen(),
      ),
      GoRoute(
        path: '/stock-adjustment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final branchId = extra?['branchId'] ?? 1;
          return StockAdjustmentScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoiceListScreen(),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (context, state) {
          final idString = state.pathParameters['id'];
          final id = int.tryParse(idString ?? '') ?? 0;
          return InvoiceDetailScreen(invoiceId: id);
        },
      ),
      GoRoute(
        path: '/daily-summary',
        builder: (context, state) => const DailySummaryScreen(),
      ),
      GoRoute(
        path: '/employee-management',
        builder: (context, state) => const EmployeeManagementScreen(),
      ),
      GoRoute(
        path: '/store-schedule',
        builder: (context, state) => const StoreScheduleBuilderScreen(),
      ),
      GoRoute(
        path: '/personal-schedule',
        builder: (context, state) => const PersonalScheduleScreen(),
      ),
      GoRoute(
        path: '/clock-in',
        builder: (context, state) => const ClockInScreen(),
      ),
      GoRoute(
        path: '/attendance-report',
        builder: (context, state) => const AttendanceReportScreen(),
      ),
      GoRoute(
        path: '/work-history',
        builder: (context, state) => const WorkHistoryScreen(),
      ),
      GoRoute(
        path: '/shift-templates',
        builder: (context, state) => const ShiftTemplatesScreen(),
      ),
    ],
  );
}
