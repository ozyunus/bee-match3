import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'variant_service.dart';

/// Thin wrapper around Firebase Analytics and variant metadata.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  static Future<void> init() async {
    try {
      final app = await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instanceFor(app: app);
    } catch (error) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firebase init failed: $error');
      }
      _analytics = null;
    }
  }

  static Map<String, Object> _withVariant(Map<String, Object?>? params) {
    final metadata = <String, Object>{
      'variant_id': VariantService.variantId,
    };
    if (params != null) {
      for (final entry in params.entries) {
        if (entry.value != null) {
          metadata[entry.key] = entry.value!;
        }
      }
    }
    return metadata;
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    if (_analytics == null) return;
    await _analytics!.logEvent(
      name: name,
      parameters: _withVariant(parameters),
    );
  }

  static Future<void> logSessionStart() async {
    await logEvent('app_session_start');
  }

  static Future<void> logSessionEnd() async {
    await logEvent('app_session_end');
  }

  static Future<void> logLevelStarted({
    required int levelId,
    required int gridSize,
    required int movesAllowed,
  }) async {
    await logEvent(
      'level_started',
      parameters: {
        'level_id': levelId,
        'grid_size': gridSize,
        'moves_allowed': movesAllowed,
      },
    );
  }

  static Future<void> logLevelComplete({
    required int levelId,
    required int score,
    required int starsEarned,
    required int movesUsed,
    required int bestCombo,
  }) async {
    await logEvent(
      'level_completed',
      parameters: {
        'level_id': levelId,
        'score': score,
        'stars_earned': starsEarned,
        'moves_used': movesUsed,
        'best_combo': bestCombo,
      },
    );
  }

  static Future<void> logLevelFailed({
    required int levelId,
    required int movesUsed,
    required int progress,
    required int target,
  }) async {
    await logEvent(
      'level_failed',
      parameters: {
        'level_id': levelId,
        'moves_used': movesUsed,
        'progress': progress,
        'target': target,
      },
    );
  }
}
