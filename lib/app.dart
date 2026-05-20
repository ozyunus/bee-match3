import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/analytics_service.dart';

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

/// Root widget with Riverpod provider scope and lifecycle tracking
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  bool _isBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsService.logSessionStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isBackground = true;
        AnalyticsService.logSessionEnd();
        break;
      case AppLifecycleState.resumed:
        if (_isBackground) {
          _isBackground = false;
          AnalyticsService.logSessionStart();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: BeeMatchApp(),
    );
  }
}
