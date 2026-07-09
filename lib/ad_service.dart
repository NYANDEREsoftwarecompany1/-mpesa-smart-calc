import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // YOUR REAL BANNER AD - MainScreen Banner
  static const String bannerAdUnitId = 'ca-app-pub-617926399180966/5661893937';
  
  // YOUR REAL INTERSTITIAL AD - Calc Interstitial  
  static const String interstitialAdUnitId = 'ca-app-pub-617926399180966/8096527141';

  static BannerAd createBannerAd(Function onAdLoaded) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
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
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (err) => null,
      ),
    );
  }
}
