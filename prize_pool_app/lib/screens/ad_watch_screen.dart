import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AdWatchScreen extends StatefulWidget {
  const AdWatchScreen({super.key});

  @override
  State<AdWatchScreen> createState() => _AdWatchScreenState();
}

class _AdWatchScreenState extends State<AdWatchScreen> {
  RewardedAd? _rewardedAd;
  bool _isLoading = true;
  bool _adWatched = false;
  String _message = 'Loading ad...';

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _loadRewardedAd() async {
    setState(() {
      _isLoading = true;
      _message = 'Loading ad...';
    });

    final adService = Provider.of<AdService>(context, listen: false);

    try {
      final ad = await adService.loadRewardedAd();

      setState(() {
        _rewardedAd = ad;
        _isLoading = false;
        _message =
            ad != null
                ? 'Ad loaded successfully! Tap the button to watch.'
                : 'Failed to load ad. Please try again later.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error loading ad: $e';
      });
    }
  }

  Future<void> _watchAd() async {
    if (_rewardedAd == null) {
      setState(() {
        _message = 'No ad available. Please try again later.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Opening ad...';
    });

    final adService = Provider.of<AdService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final bool rewardEarned = await adService.showRewardedAd(_rewardedAd!);

      if (rewardEarned && authService.user != null) {
        // Record the ad watch in the database
        await databaseService.recordAdWatch(authService.user!.uid);

        setState(() {
          _adWatched = true;
          _isLoading = false;
          _message =
              'Thank you for watching! Your contribution has been added to the prize pool.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _message = 'You need to watch the full ad to earn a reward.';
        });

        // Load a new ad
        _loadRewardedAd();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error showing ad: $e';
      });

      // Load a new ad
      _loadRewardedAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watch Ad')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Watch an Ad to Contribute',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'By watching this ad, you\'ll contribute to the prize pool that will be distributed to all participants.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              )
            else if (_adWatched)
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Return to Home'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    _message,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _rewardedAd != null ? _watchAd : _loadRewardedAd,
                    icon: Icon(
                      _rewardedAd != null ? Icons.play_arrow : Icons.refresh,
                    ),
                    label: Text(
                      _rewardedAd != null ? 'Watch Ad Now' : 'Reload Ad',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
