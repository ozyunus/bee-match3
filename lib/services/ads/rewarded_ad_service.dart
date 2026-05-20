import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

/// Manages loading and showing a single rewarded ad unit.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  static const bool _useTestAds = bool.fromEnvironment(
    'USE_TEST_ADS',
    defaultValue: false,
  );

  static const _productionAdUnitId = 'ca-app-pub-9329505100406975/4853288929';
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static String get _adUnitId =>
      (kDebugMode || _useTestAds) ? _testAdUnitId : _productionAdUnitId;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  Completer<RewardedAd?>? _loadCompleter;
  int _loadRetryCount = 0;
  String? _lastLoadErrorMessage;

  static const int _maxLoadRetries = 3;

  bool get isAdReady => _rewardedAd != null;

  bool get isLoading => _isLoading;

  String? get lastLoadErrorMessage => _lastLoadErrorMessage;

  void _logResponseInfo(ResponseInfo? responseInfo, {String prefix = ''}) {
    if (!(kDebugMode || _useTestAds)) return;

    if (responseInfo == null) {
      // ignore: avoid_print
      print('${prefix}responseInfo: null');
      return;
    }

    // ignore: avoid_print
    print(
      '${prefix}responseId=${responseInfo.responseId}, '
      'mediationAdapter=${responseInfo.mediationAdapterClassName}',
    );

    final adapters = responseInfo.adapterResponses ?? const <AdapterResponseInfo>[];
    for (final adapter in adapters) {
      // ignore: avoid_print
      print(
        '${prefix}adapter=${adapter.adapterClassName}, '
        'source=${adapter.adSourceName}, '
        'sourceId=${adapter.adSourceId}, '
        'instance=${adapter.adSourceInstanceName}, '
        'instanceId=${adapter.adSourceInstanceId}, '
        'latencyMs=${adapter.latencyMillis}, '
        'error=${adapter.adError}',
      );
    }
  }

  void loadRewardedAd() {
    if (_rewardedAd != null || _isLoading) return;
    _isLoading = true;
    final completer = Completer<RewardedAd?>();
    _loadCompleter = completer;
    if (kDebugMode || _useTestAds) {
      // ignore: avoid_print
      print(
        'Loading rewarded ad from $_adUnitId '
        '(debugMode=$kDebugMode, useTestAds=$_useTestAds)',
      );
    }
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          _loadRetryCount = 0;
          _lastLoadErrorMessage = null;
          if (!completer.isCompleted) {
            completer.complete(ad);
          }
          _loadCompleter = null;
          if (kDebugMode || _useTestAds) {
            // ignore: avoid_print
            print('Rewarded ad loaded successfully.');
            _logResponseInfo(ad.responseInfo, prefix: '  ');
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          _lastLoadErrorMessage =
              'code=${error.code}, domain=${error.domain}, message=${error.message}';
          if (error.responseInfo?.responseId != null) {
            _lastLoadErrorMessage =
                '$_lastLoadErrorMessage, responseId=${error.responseInfo?.responseId}';
          }
          if (!completer.isCompleted) {
            completer.complete(null);
          }
          _loadCompleter = null;
          if (kDebugMode || _useTestAds) {
            // ignore: avoid_print
            print('Rewarded ad failed to load: $error');
            _logResponseInfo(error.responseInfo, prefix: '  ');
          }
          if (_loadRetryCount < _maxLoadRetries) {
            _loadRetryCount++;
            Future.delayed(const Duration(seconds: 2), () {
              loadRewardedAd();
            });
          }
        },
      ),
    );
  }

  Future<bool> ensureRewardedAdReady({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_rewardedAd != null) {
      return true;
    }

    loadRewardedAd();

    final completer = _loadCompleter;
    if (completer == null) {
      return _rewardedAd != null;
    }

    try {
      final ad = await completer.future.timeout(timeout);
      return ad != null;
    } on TimeoutException {
      return _rewardedAd != null;
    }
  }

  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdFailedToShow,
  }) {
    final ad = _rewardedAd;
    if (ad == null) {
      onAdFailedToShow?.call();
      loadRewardedAd();
      return;
    }

    if (kDebugMode || _useTestAds) {
      // ignore: avoid_print
      print('Showing rewarded ad from $_adUnitId.');
      _logResponseInfo(ad.responseInfo, prefix: '  ');
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (kDebugMode || _useTestAds) {
          // ignore: avoid_print
          print('Rewarded ad failed to show: $error');
        }
        onAdFailedToShow?.call();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward();
      },
    );
  }
}
