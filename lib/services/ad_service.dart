import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialReady = false;

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  static void showInterstitialIfReady() {
    if (_isInterstitialReady && _interstitialAd!= null) {
      _interstitialAd!.show();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialReady = false;
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialReady = false;
          loadInterstitialAd();
        },
      );
    } else {
      loadInterstitialAd();
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