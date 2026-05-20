import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/level_complete_screen.dart';
import '../../presentation/screens/level_failed_screen.dart';
import '../../presentation/screens/settings_screen.dart';

/// Route names
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String game = '/game';
  static const String levelComplete = '/level-complete';
  static const String levelFailed = '/level-failed';
  static const String settings = '/settings';
}

/// App router configuration
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.game,
        name: 'game',
        builder: (context, state) {
          final levelId = state.extra as int? ?? 1;
          return GameScreen(levelId: levelId);
        },
      ),
      GoRoute(
        path: AppRoutes.levelComplete,
        name: 'levelComplete',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return LevelCompleteScreen(
            levelId: data['levelId'] as int? ?? 1,
            score: data['score'] as int? ?? 0,
            starsEarned: data['starsEarned'] as int? ?? 1,
            movesUsed: data['movesUsed'] as int? ?? 0,
            bestCombo: data['bestCombo'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.levelFailed,
        name: 'levelFailed',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return LevelFailedScreen(
            levelId: data['levelId'] as int? ?? 1,
            currentProgress: data['currentProgress'] as int? ?? 0,
            targetProgress: data['targetProgress'] as int? ?? 30,
            objectiveLabel: data['objectiveLabel'] as String? ?? 'Collect Bees',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
