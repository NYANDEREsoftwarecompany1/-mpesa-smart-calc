import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // TEST IDS - REPLACE WITH YOUR REAL IDS BEFORE PUBLISH
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  static BannerAd createBannerAd(Function onAdLoaded) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  static void loadInterstitialAd(Function(InterstitialAd) onAdLoaded) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (err) => null,
      ),
    );
  }
}
