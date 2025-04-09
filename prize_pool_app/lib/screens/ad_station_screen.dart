import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../widgets/app_drawer.dart';

class AdStationScreen extends StatefulWidget {
  const AdStationScreen({super.key});

  @override
  State<AdStationScreen> createState() => _AdStationScreenState();
}

class _AdStationScreenState extends State<AdStationScreen> {
  bool _isLoading = false;
  bool _canWatchAd = false;
  bool _adWatched = false;
  dynamic _rewardedAd;

  @override
  void initState() {
    super.initState();
    _checkAdStatus();
  }

  Future<void> _checkAdStatus() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = DatabaseService();
    
    if (authService.user != null) {
      final canWatch = await databaseService.canWatchAdToday(authService.user!.uid);
      setState(() {
        _canWatchAd = canWatch;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAd() async {
    setState(() {
      _isLoading = true;
    });

    final adService = AdService();
    _rewardedAd = await adService.loadRewardedAd();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _watchAd() async {
    if (_rewardedAd == null) {
      await _loadAd();
      if (_rewardedAd == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load ad. Please try again later.'),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    final adService = AdService();
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = DatabaseService();

    final bool rewardEarned = await adService.showRewardedAd(_rewardedAd);
    
    if (rewardEarned && authService.user != null) {
      await databaseService.recordAdWatch(authService.user!.uid);
      
      setState(() {
        _adWatched = true;
        _canWatchAd = false;
      });
    }

    setState(() {
      _isLoading = false;
      _rewardedAd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Watching Station'),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_filled,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Ad Watching Station',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Watch one ad per day to contribute to the prize pool. The more people watch ads, the bigger the prize pool gets!',
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
                    const Text(
                      'Thank you for watching an ad today!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You\'ve contributed to the prize pool.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text('Return to Home'),
                    ),
                  ],
                )
              else if (!_canWatchAd)
                Column(
                  children: [
                    const Icon(Icons.access_time, color: Colors.orange, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'You\'ve already watched an ad today!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Come back tomorrow for more earnings!',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text('Return to Home'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    const Text(
                      'Ready to watch an ad?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can watch one ad per day to contribute to the prize pool.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Ad Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _watchAd,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
