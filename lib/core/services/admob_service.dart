import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  static final AdmobService _instance = AdmobService._internal();
  factory AdmobService() => _instance;
  AdmobService._internal();

  // ── AdMob IDs ─────────────────────────────────────────────────────────────
  // Production App ID: ca-app-pub-3957846228342473~4594065674
  static const String prodInterstitialAdUnitId =
      'ca-app-pub-3957846228342473/6585173307';

  // Google Test Interstitial Unit ID (used when in debug mode if needed)
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static String get interstitialAdUnitId {
    // In debug mode on Android/iOS, use test unit ID or prod unit ID
    if (kDebugMode) {
      return Platform.isAndroid
          ? testInterstitialAdUnitId
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return prodInterstitialAdUnitId;
  }

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  int _retryAttempts = 0;
  DateTime? _lastAdShownTime;

  // Minimum interval between interstitial ads to protect user experience (60 seconds)
  static const Duration minAdInterval = Duration(seconds: 60);

  bool _initialized = false;

  /// Initialize AdMob SDK and preload the first interstitial ad
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return;

      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdmobService] Google Mobile Ads initialized successfully');
      loadInterstitialAd();
    } catch (e) {
      debugPrint('[AdmobService] Initialization notice: $e');
    }
  }

  /// Preload an Interstitial Ad in background
  void loadInterstitialAd() {
    if (_isLoading || _interstitialAd != null) return;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          _retryAttempts = 0;
          debugPrint('[AdmobService] Interstitial Ad loaded and ready');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdmobService] Interstitial Ad failed to load: ${error.message}');
          _interstitialAd = null;
          _isLoading = false;
          _retryAttempts++;

          // Exponential backoff retry (up to 4 attempts)
          if (_retryAttempts < 5) {
            final delaySeconds = pow(2, _retryAttempts).toInt().clamp(4, 60);
            Timer(Duration(seconds: delaySeconds), () {
              loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  /// Show Interstitial Ad if available and cooldown has elapsed.
  /// Calls [onDismissed] callback when the ad is closed or if no ad was shown.
  void showInterstitialAd({VoidCallback? onDismissed}) {
    // Check cooldown
    final now = DateTime.now();
    if (_lastAdShownTime != null && now.difference(_lastAdShownTime!) < minAdInterval) {
      debugPrint('[AdmobService] Skipping ad: Cooldown active');
      onDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('[AdmobService] Skipping ad: Ad not ready yet');
      loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdmobService] Interstitial ad showing full screen');
        _lastAdShownTime = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdmobService] Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd(); // Preload next
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('[AdmobService] Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        loadInterstitialAd();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }

  /// Randomly show an interstitial ad based on [chance] (0.0 to 1.0)
  void showRandomInterstitial({double chance = 0.5, VoidCallback? onDismissed}) {
    final random = Random().nextDouble();
    if (random <= chance) {
      showInterstitialAd(onDismissed: onDismissed);
    } else {
      onDismissed?.call();
    }
  }
}
