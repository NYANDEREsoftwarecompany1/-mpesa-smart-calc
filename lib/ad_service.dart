import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          print('Interstitial failed: $error');
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
