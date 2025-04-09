import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/prize_pool_model.dart';
import '../widgets/app_drawer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PrizePoolModel> _prizePools = [];
  bool _isLoading = true;
  bool _canWatchAd = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final databaseService = Provider.of<DatabaseService>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.user != null) {
      final pools = await databaseService.getPrizePools();
      final canWatch = await databaseService.canWatchAdToday(
        authService.user!.uid,
      );

      setState(() {
        _prizePools = pools;
        _canWatchAd = canWatch;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Prize Pool App')),
      drawer: const AppDrawer(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User welcome section
                      if (user != null)
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${user.username}!',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Total ads watched: ${user.adWatchCount}'),
                                Text(
                                  'Total earnings: \$${user.earnings.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Watch ad button
                      if (_canWatchAd)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/ad_watch');
                            },
                            icon: const Icon(Icons.play_circle_filled),
                            label: const Text('Watch Ad & Earn'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Card(
                            color: Colors.amber.shade100,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 48,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You\'ve already watched an ad today',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Come back tomorrow for more earnings!',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Current prize pool
                      const Text(
                        'Current Prize Pool',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_prizePools.isNotEmpty)
                        _buildCurrentPrizePool(_prizePools.first)
                      else
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No active prize pool yet.'),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Past distributions
                      const Text(
                        'Past Distributions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPastDistributions(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCurrentPrizePool(PrizePoolModel pool) {
    final now = DateTime.now();
    final daysLeft = pool.distributionDate.difference(now).inDays;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:', style: TextStyle(fontSize: 16)),
                Text(
                  '\$${pool.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Participants:', style: TextStyle(fontSize: 16)),
                Text(
                  '${pool.participantCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distribution Date:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(pool.distributionDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Days Left:', style: TextStyle(fontSize: 16)),
                Text(
                  '$daysLeft days',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: daysLeft < 3 ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 1 - (daysLeft / 7), // Assuming 7-day distribution cycle
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                daysLeft < 3 ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your potential share: \$${pool.prizePerParticipant.toStringAsFixed(2)}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastDistributions() {
    final pastPools = _prizePools.where((pool) => pool.isDistributed).toList();

    if (pastPools.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No past distributions yet.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pastPools.length,
      itemBuilder: (context, index) {
        final pool = pastPools[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(
              'Distribution on ${DateFormat('MMM dd, yyyy').format(pool.distributionDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Amount: \$${pool.totalAmount.toStringAsFixed(2)} • Participants: ${pool.participantCount}',
            ),
            trailing: Text(
              '\$${pool.prizePerParticipant.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
