import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'services/ads/rewarded_ad_service.dart';
import 'services/analytics_service.dart';
import 'services/onboarding_service.dart';
import 'services/sound_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await UserService.init();

  // Initialize sound effects
  await SoundService.init();

  // Initialize Firebase analytics (gameplay events)
  await AnalyticsService.init();

  // Initialize Setgreet onboarding flags
  await OnboardingService.init();
  await OnboardingService.identifyUser();

  // Initialize Google Mobile Ads & preload rewarded ad
  if (kDebugMode) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['7A5623F490C83D29F8303934A14188C7'],
      ),
    );
  }
  await MobileAds.instance.initialize();
  RewardedAdService.instance.loadRewardedAd();

  // Set preferred orientations (portrait only for mobile game)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AppRoot());
}
