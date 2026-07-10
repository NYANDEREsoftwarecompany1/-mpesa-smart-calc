import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // SET HII KUWA true WAKATI WA TESTING, false UKI-UPLOAD PLAY STORE
  static const bool isTestMode = true;

  // --- APP ID YAKO (FIXED NA ~ ) ---
  static const String _appId = "ca-app-pub-617926399180966~8938793961";

  // --- REAL IDs ZAKO ---
  static const String _realBannerId = "ca-app-pub-617926399180966/XXXXXXXXXX"; // weka Banner ID yako hapa
  static const String _realInterstitialId = "ca-app-pub-617926399180966/YYYYYYYYYY"; // weka Interstitial ID yako

  // --- GOOGLE TEST IDs (Zinawork 100% instantly) ---
  static const String _testBannerId = "ca-app-pub-3940256099942544/6300978111";
  static const String _testInterstitialId = "ca-app-pub-3940256099942544/1033173712";

  static String get bannerAdUnitId => isTestMode ? _testBannerId : _realBannerId;
  static String get interstitialAdUnitId => isTestMode ? _testInterstitialId : _realInterstitialId;

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => print("✅ BANNER LOADED: $bannerAdUnitId"),
        onAdFailedToLoad: (ad, err) {
          print("❌ BANNER FAILED: ${err.message}");
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
        onAdLoaded: (ad) {
          print("✅ INTERSTITIAL READY");
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (err) => print("❌ INTERSTITIAL FAILED: ${err.message}"),
      ),
    );
  }
}
