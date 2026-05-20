import 'package:flutter/foundation.dart';
import 'package:setgreet/setgreet.dart';

import 'user_service.dart';
import 'variant_service.dart';

/// Responsible for initializing and identifying the user in the Setgreet SDK.
class OnboardingService {
  OnboardingService._();

  static const _appKey = String.fromEnvironment(
    'SETGREET_APP_KEY',
    defaultValue: '69d39ddfaf9ebaf45702ca6dc',
  );
  static const _flowId = String.fromEnvironment(
    'SETGREET_FLOW_ID',
    defaultValue: '',
  );
  static bool _initialized = false;

  static bool get hasFlow => _flowId.isNotEmpty;

  static Future<void> init() async {
    if (_initialized) return;
    if (_appKey.isEmpty) {
      VariantService.setFallbackVariant();
      return;
    }

    try {
      await Setgreet.initialize(
        _appKey,
        config: const SetgreetConfig(debugMode: true),
      );
      _initialized = true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Setgreet init failed: $error');
      }
      VariantService.setFallbackVariant();
    }
  }

  static Future<void> identifyUser() async {
    if (!_initialized) return;
    await Setgreet.identifyUser(
      UserService.uuid,
      attributes: {'app_version': 'v1'},
    );
  }

  static Future<bool> launchFlowIfAvailable() async {
    if (!_initialized) {
      return false;
    }

    try {
      debugPrint('Setgreet splaaash');
      await Setgreet.trackScreen('splash');
      // await Setgreet.showFlow(_flowId);
      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Setgreet flow failed: $error');
      }
      return false;
    }
  }
}
