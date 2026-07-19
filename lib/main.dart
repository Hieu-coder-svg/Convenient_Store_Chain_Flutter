import 'package:convenient_store_chain_flutter/features/pos/providers/invoice_provider.dart';
import 'package:convenient_store_chain_flutter/features/pos/services/invoice_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/network/dio_client.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/product/services/product_api_service.dart';
import 'features/product/providers/product_catalog_provider.dart';
import 'features/supplier/services/supplier_api_service.dart';
import 'features/supplier/providers/supplier_provider.dart';
import 'features/branch/services/branch_api_service.dart';
import 'features/branch/providers/branch_provider.dart';
import 'features/user_management/services/user_service.dart';
import 'features/user_management/providers/user_provider.dart';
import 'features/branch_order/services/branch_order_api_service.dart';
import 'features/branch_order/providers/branch_order_provider.dart';
import 'features/pos/services/customer_api_service.dart';
import 'features/pos/providers/customer_provider.dart';
import 'features/pos/providers/cart_provider.dart';
import 'features/inventory/services/inventory_api_service.dart';
import 'features/inventory/providers/inventory_provider.dart';
import 'features/notification/services/notification_api_service.dart';
import 'features/notification/providers/notification_provider.dart';
import 'features/purchase_order/services/purchase_order_api_service.dart';
import 'features/purchase_order/providers/purchase_order_provider.dart';
import 'features/user_management/services/hr_service.dart';
import 'features/user_management/providers/hr_provider.dart';
import 'features/reports/providers/reports_provider.dart';

void main() {
  runApp(const ConvenienceStoreApp());
}

class ConvenienceStoreApp extends StatelessWidget {
  const ConvenienceStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DioClient>(create: (_) => DioClient()),
        ProxyProvider<DioClient, AuthService>(
          update: (context, dioClient, previous) => AuthService(dioClient),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
          update: (context, authService, previous) =>
              previous ?? AuthProvider(authService),
        ),
        ProxyProvider<DioClient, ProductApiService>(
          update: (context, dioClient, previous) =>
              previous ?? ProductApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<ProductApiService, ProductCatalogProvider>(
          create: (context) =>
              ProductCatalogProvider(context.read<ProductApiService>()),
          update: (context, apiService, previous) =>
              previous ?? ProductCatalogProvider(apiService),
        ),
        ProxyProvider<DioClient, SupplierApiService>(
          update: (context, dioClient, previous) =>
              previous ?? SupplierApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<SupplierApiService, SupplierProvider>(
          create: (context) =>
              SupplierProvider(context.read<SupplierApiService>()),
          update: (context, apiService, previous) =>
              previous ?? SupplierProvider(apiService),
        ),
        ProxyProvider<DioClient, BranchApiService>(
          update: (context, dioClient, previous) =>
              previous ?? BranchApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<BranchApiService, BranchProvider>(
          create: (context) => BranchProvider(context.read<BranchApiService>()),
          update: (context, apiService, previous) =>
              previous ?? BranchProvider(apiService),
        ),
        ProxyProvider<DioClient, UserService>(
          update: (context, dioClient, previous) => UserService(dioClient),
        ),
        ChangeNotifierProxyProvider<UserService, UserProvider>(
          create: (context) => UserProvider(context.read<UserService>()),
          update: (context, userService, previous) =>
              previous ?? UserProvider(userService),
        ),
        ProxyProvider<DioClient, BranchOrderApiService>(
          update: (context, dioClient, previous) =>
              previous ?? BranchOrderApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<BranchOrderApiService, BranchOrderProvider>(
          create: (context) =>
              BranchOrderProvider(context.read<BranchOrderApiService>()),
          update: (context, apiService, previous) =>
              previous ?? BranchOrderProvider(apiService),
        ),
        ProxyProvider<DioClient, CustomerApiService>(
          update: (context, dioClient, previous) =>
              previous ?? CustomerApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<CustomerApiService, CustomerProvider>(
          create: (context) =>
              CustomerProvider(context.read<CustomerApiService>()),
          update: (context, apiService, previous) =>
              previous ?? CustomerProvider(apiService),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ProxyProvider<DioClient, HrService>(
          update: (context, dioClient, previous) => HrService(dioClient),
        ),
        ChangeNotifierProxyProvider<HrService, HrProvider>(
          create: (context) => HrProvider(context.read<HrService>()),
          update: (context, hrService, previous) =>
              previous ?? HrProvider(hrService),
        ),
        ProxyProvider<DioClient, InvoiceApiService>(
          update: (context, dioClient, previous) =>
              previous ?? InvoiceApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<InvoiceApiService, InvoiceProvider>(
          create: (context) =>
              InvoiceProvider(context.read<InvoiceApiService>()),
          update: (context, apiService, previous) =>
              previous ?? InvoiceProvider(apiService),
        ),
        ProxyProvider<DioClient, InventoryApiService>(
          update: (context, dioClient, previous) => previous ?? InventoryApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<InventoryApiService, InventoryProvider>(
          create: (context) => InventoryProvider(context.read<InventoryApiService>()),
          update: (context, apiService, previous) => previous ?? InventoryProvider(apiService),
        ),
        ProxyProvider<DioClient, NotificationApiService>(
          update: (context, dioClient, previous) => previous ?? NotificationApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<NotificationApiService, NotificationProvider>(
          create: (context) => NotificationProvider(context.read<NotificationApiService>()),
          update: (context, apiService, previous) => previous ?? NotificationProvider(apiService),
        ),
        ProxyProvider<DioClient, PurchaseOrderApiService>(
          update: (context, dioClient, previous) => previous ?? PurchaseOrderApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<PurchaseOrderApiService, PurchaseOrderProvider>(
          create: (context) => PurchaseOrderProvider(context.read<PurchaseOrderApiService>()),
          update: (context, apiService, previous) => previous ?? PurchaseOrderProvider(apiService),
        ),
        ChangeNotifierProxyProvider<DioClient, ReportsProvider>(
          create: (context) => ReportsProvider(context.read<DioClient>()),
          update: (context, dioClient, previous) => previous ?? ReportsProvider(dioClient),
        ),
      ],
      child: MaterialApp.router(
        title: 'Convenience Store POS',
        theme: AppTheme.lightTheme,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
