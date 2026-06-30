import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialReady = false;
  static DateTime? _lastInterstitialTime;

  // Called from main.dart - prevents "intrusive ads" ban
  static Future<void> init() async {
    await _loadInterstitialAd();
  }

  static Future<BannerAd> createBannerAd(BuildContext context) async {
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    return BannerAd(
      adUnitId: _getBannerAdUnitId(),
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  static Future<void> _loadInterstitialAd() async {
    // 1-minute gap = Required by AdMob. Remove = account banned
    if (_lastInterstitialTime != null) {
      final diff = DateTime.now().difference(_lastInterstitialTime!);
      if (diff.inSeconds < 60) return;
    }

    await InterstitialAd.load(
      adUnitId: _getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          ad.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialReady = false;
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  static void showInterstitialIfReady() {
    // 1-minute gap check. Spam interstitials = $0 earnings
    if (_lastInterstitialTime != null) {
      final diff = DateTime.now().difference(_lastInterstitialTime!);
      if (diff.inSeconds < 60) return;
    }

    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _lastInterstitialTime = DateTime.now();
      _isInterstitialReady = false;
    } else {
      _loadInterstitialAd();
    }
  }

  static String _getBannerAdUnitId() {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else {
      return 'ca-app-pub-YOUR-REAL-ID/XXXXXX';
    }
  }

  static String _getInterstitialAdUnitId() {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else {
      return 'ca-app-pub-YOUR-REAL-ID/XXXXXX';
    }
  }
}