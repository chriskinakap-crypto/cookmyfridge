import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static bool _initialized = false;

  // ── Ad Unit IDs ────────────────────────────────────────────────────────────
  // Replace test IDs with your real AdMob IDs from admob.google.com
  static const _bannerIdAndroid     = 'ca-app-pub-3940256099942544/6300978111'; // TEST
  static const _interstitialIdAndroid = 'ca-app-pub-3940256099942544/1033173712'; // TEST
  static const _rewardedIdAndroid   = 'ca-app-pub-3940256099942544/5224354917'; // TEST
  static const _bannerIdIOS         = 'ca-app-pub-3940256099942544/2934735716'; // TEST
  static const _interstitialIdIOS   = 'ca-app-pub-3940256099942544/4411468910'; // TEST
  static const _rewardedIdIOS       = 'ca-app-pub-3940256099942544/1712485313'; // TEST

  static String get _bannerId       => defaultTargetPlatform == TargetPlatform.iOS ? _bannerIdIOS : _bannerIdAndroid;
  static String get _interstitialId => defaultTargetPlatform == TargetPlatform.iOS ? _interstitialIdIOS : _interstitialIdAndroid;
  static String get _rewardedId     => defaultTargetPlatform == TargetPlatform.iOS ? _rewardedIdIOS : _rewardedIdAndroid;

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  // ── Banner Ad ─────────────────────────────────────────────────────────────
  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => debugPrint('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) { debugPrint('Banner failed: $error'); ad.dispose(); },
      ),
    );
  }

  // ── Interstitial Ad (shown after every 3rd recipe search) ─────────────────
  static InterstitialAd? _interstitial;
  static int _searchCount = 0;

  static Future<void> loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) { _interstitial = ad; debugPrint('Interstitial loaded'); },
        onAdFailedToLoad: (error) { debugPrint('Interstitial failed: $error'); _interstitial = null; },
      ),
    );
  }

  static void onRecipeSearch() {
    _searchCount++;
    // Show interstitial every 3 searches for free users
    if (_searchCount % 3 == 0 && _interstitial != null) {
      _interstitial!.show();
      _interstitial = null;
      loadInterstitial(); // preload next
    }
  }

  // ── Rewarded Ad (unlock extra recipes) ───────────────────────────────────
  static RewardedAd? _rewarded;

  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) { _rewarded = ad; debugPrint('Rewarded ad loaded'); },
        onAdFailedToLoad: (error) { debugPrint('Rewarded failed: $error'); _rewarded = null; },
      ),
    );
  }

  static void showRewardedAd({required Function() onRewarded}) {
    if (_rewarded == null) { onRewarded(); return; } // fallback: give reward anyway
    _rewarded!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _rewarded = null; loadRewardedAd(); },
      onAdFailedToShowFullScreenContent: (ad, error) { ad.dispose(); onRewarded(); },
    );
    _rewarded!.show(onUserEarnedReward: (_, reward) => onRewarded());
  }

  static bool get isRewardedReady => _rewarded != null;

  static void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
