import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';

/// Main application widget
class BeeMatchApp extends StatelessWidget {
  const BeeMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bee Match',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Force light mode for now
      routerConfig: AppRouter.router,
    );
  }
}

/// Root widget with Riverpod provider scope
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: BeeMatchApp(),
    );
  }
}
