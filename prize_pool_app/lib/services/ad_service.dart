import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Mock RewardedAd class for when AdMob isn't available
class MockRewardedAd {
  void dispose() {}

  Future<void> show({required Function onUserEarnedReward}) async {
    // Simulate ad viewing delay
    await Future.delayed(const Duration(seconds: 3));
    onUserEarnedReward(null, null);
    return;
  }
}

class AdService {
  // Flag to indicate if we're using mock ads
  // Set this to false when using real AdMob
  final bool _useMockAds = false;

  // Test ad units for development
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production ad units (replace with your actual ad unit IDs)
  static const String _prodRewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';

  // Use test ads for debug mode, real ads for release
  String get rewardedAdUnitId {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    } else {
      return _prodRewardedAdUnitId;
    }
  }

  // Load a rewarded ad
  Future<dynamic> loadRewardedAd() async {
    if (_useMockAds) {
      // Simulate loading delay
      await Future.delayed(const Duration(seconds: 1));
      return MockRewardedAd();
    } else {
      // Real AdMob implementation
      RewardedAd? rewardedAd;

      try {
        await RewardedAd.load(
          adUnitId: rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              rewardedAd = ad;
            },
            onAdFailedToLoad: (error) {
              print('Rewarded ad failed to load: ${error.message}');
            },
          ),
        );
      } catch (e) {
        print('Error loading rewarded ad: $e');
      }

      return rewardedAd;
    }
  }

  // Show a rewarded ad and return whether the user earned a reward
  Future<bool> showRewardedAd(dynamic ad) async {
    bool rewardEarned = false;

    if (_useMockAds && ad is MockRewardedAd) {
      await ad.show(
        onUserEarnedReward: (_, __) {
          rewardEarned = true;
        },
      );
      return rewardEarned;
    } else if (ad is RewardedAd) {
      // Real AdMob implementation
      try {
        await ad.show(
          onUserEarnedReward: (_, reward) {
            rewardEarned = true;
          },
        );

        // Dispose the ad after showing it
        ad.dispose();
      } catch (e) {
        print('Error showing rewarded ad: $e');
      }

      return rewardEarned;
    }

    return false;
  }

  // Initialize mobile ads SDK
  Future<void> initialize() async {
    if (_useMockAds) {
      // Mock initialization
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    } else {
      // Real AdMob initialization
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        print('Error initializing AdMob: $e');
      }
    }
  }
}
