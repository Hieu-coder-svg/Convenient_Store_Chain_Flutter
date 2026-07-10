import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/network/dio_client.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/providers/auth_provider.dart';
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
