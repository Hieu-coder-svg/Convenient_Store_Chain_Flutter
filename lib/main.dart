import 'package:flutter/material.dart';
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

void main() {
  runApp(const ConvenienceStoreApp());
}

class ConvenienceStoreApp extends StatelessWidget {
  const ConvenienceStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DioClient>(
          create: (_) => DioClient(),
        ),
        ProxyProvider<DioClient, AuthService>(
          update: (context, dioClient, previous) => AuthService(dioClient),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
          update: (context, authService, previous) => previous ?? AuthProvider(authService),
        ),
        ProxyProvider<DioClient, ProductApiService>(
          update: (context, dioClient, previous) => previous ?? ProductApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<ProductApiService, ProductCatalogProvider>(
          create: (context) => ProductCatalogProvider(context.read<ProductApiService>()),
          update: (context, apiService, previous) => previous ?? ProductCatalogProvider(apiService),
        ),
        ProxyProvider<DioClient, SupplierApiService>(
          update: (context, dioClient, previous) => previous ?? SupplierApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<SupplierApiService, SupplierProvider>(
          create: (context) => SupplierProvider(context.read<SupplierApiService>()),
          update: (context, apiService, previous) => previous ?? SupplierProvider(apiService),
        ),
        ProxyProvider<DioClient, BranchApiService>(
          update: (context, dioClient, previous) => previous ?? BranchApiService(dioClient),
        ),
        ChangeNotifierProxyProvider<BranchApiService, BranchProvider>(
          create: (context) => BranchProvider(context.read<BranchApiService>()),
          update: (context, apiService, previous) => previous ?? BranchProvider(apiService),
        ),
        ProxyProvider<DioClient, UserService>(
          update: (context, dioClient, previous) => UserService(dioClient),
        ),
        ChangeNotifierProxyProvider<UserService, UserProvider>(
          create: (context) => UserProvider(context.read<UserService>()),
          update: (context, userService, previous) => previous ?? UserProvider(userService),
        ),
      ],
      child: MaterialApp.router(
        title: 'Convenience Store POS',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
