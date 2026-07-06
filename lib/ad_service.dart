import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  // YOUR REAL ADMOB IDs - MONEY STARTS HERE
  static const String bannerAdUnitId = 'ca-app-pub-6179269399180966/2956543811';
  static const String interstitialAdUnitId = 'ca-app-pub-6179269399180966/6798374451';

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.setImmersiveMode(true);
          print('✅ REAL INTERSTITIAL LOADED');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          print('❌ Interstitial failed: $error');
        },
      ),
    );
  }

  static void showInterstitialIfReady() {
    if (_isInterstitialAdReady && _interstitialAd!= null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
      _interstitialAd = null;
    }
  }
}
