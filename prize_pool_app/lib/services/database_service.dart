import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/prize_pool_model.dart';

class DatabaseService {
  // Firebase Firestore instance

  // Collections
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference _prizePoolsCollection = FirebaseFirestore.instance
      .collection('prize_pools');
  final CollectionReference _adWatchesCollection = FirebaseFirestore.instance
      .collection('ad_watches');

  // Demo data - used only in demo mode
  final Map<String, UserModel> _users = {};
  final List<PrizePoolModel> _prizePools = [];
  final List<Map<String, dynamic>> _adWatches = [];

  // Flag to indicate if we're in demo mode
  // Set this to false when using real Firebase
  final bool _demoMode = false;

  // Constructor - initialize with demo data if in demo mode
  DatabaseService() {
    if (_demoMode) {
      _initDemoData();
    }
  }

  void _initDemoData() {
    // Create a demo prize pool
    final now = DateTime.now();
    final distributionDate = now.add(const Duration(days: 7));

    final demoPool = PrizePoolModel(
      id: 'demo-pool-1',
      totalAmount: 125.50,
      participantCount: 50,
      distributionDate: distributionDate,
      isDistributed: false,
    );

    // Create a past prize pool
    final pastPool = PrizePoolModel(
      id: 'demo-pool-0',
      totalAmount: 98.75,
      participantCount: 42,
      distributionDate: now.subtract(const Duration(days: 7)),
      isDistributed: true,
    );

    _prizePools.add(demoPool);
    _prizePools.add(pastPool);
  }

  // User methods
  Future<void> createUser(UserModel user) async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _users[user.uid] = user;
    } else {
      // In Firebase mode, save to Firestore
      await _usersCollection.doc(user.uid).set(user.toMap());
    }
  }

  Future<UserModel?> getUser(String uid) async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      return _users[uid];
    } else {
      // In Firebase mode, get from Firestore
      final DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      _users[user.uid] = user;
    } else {
      // In Firebase mode, update in Firestore
      await _usersCollection.doc(user.uid).update(user.toMap());
    }
  }

  // Ad watch methods
  Future<void> recordAdWatch(String userId) async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Get the user
      final user = _users[userId];
      if (user == null) return;

      // Update user's ad watch count and last watch time
      final updatedUser = user.copyWith(
        adWatchCount: user.adWatchCount + 1,
        lastAdWatchTime: DateTime.now(),
      );

      // Update user in demo database
      _users[userId] = updatedUser;

      // Record the ad watch
      _adWatches.add({
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'revenueGenerated':
            0.01, // Example value, adjust based on actual ad revenue
      });

      // Update the current prize pool
      await _updatePrizePool(0.01); // Add the ad revenue to the prize pool
    } else {
      // In Firebase mode
      // Get the user from Firestore
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return;

      final UserModel user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userId,
      );

      // Update user's ad watch count and last watch time
      final updatedUser = user.copyWith(
        adWatchCount: user.adWatchCount + 1,
        lastAdWatchTime: DateTime.now(),
      );

      // Update user in Firestore
      await _usersCollection.doc(userId).update(updatedUser.toMap());

      // Record the ad watch in Firestore
      await _adWatchesCollection.add({
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'revenueGenerated':
            0.01, // Example value, adjust based on actual ad revenue
      });

      // Update the current prize pool
      await _updatePrizePool(0.01); // Add the ad revenue to the prize pool
    }
  }

  // Prize pool methods
  Future<void> _updatePrizePool(double amount) async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the current active prize pool
      final activePool = _prizePools.firstWhere(
        (pool) => !pool.isDistributed,
        orElse: () => _createNewPrizePool(amount),
      );

      // Update the pool
      final index = _prizePools.indexWhere((pool) => pool.id == activePool.id);
      if (index >= 0) {
        final updatedPool = PrizePoolModel(
          id: activePool.id,
          totalAmount: activePool.totalAmount + amount,
          participantCount: activePool.participantCount + 1,
          distributionDate: activePool.distributionDate,
          isDistributed: false,
        );

        _prizePools[index] = updatedPool;
      }
    } else {
      // In Firebase mode
      // Get the current active prize pool from Firestore
      final QuerySnapshot snapshot =
          await _prizePoolsCollection
              .where('isDistributed', isEqualTo: false)
              .orderBy('distributionDate', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        // Create a new prize pool
        final newPool = _createNewPrizePool(amount);
        await _prizePoolsCollection.doc(newPool.id).set(newPool.toMap());
      } else {
        // Update existing prize pool
        final doc = snapshot.docs.first;
        final poolId = doc.id;
        final poolData = doc.data() as Map<String, dynamic>;

        final activePool = PrizePoolModel.fromMap(poolData, poolId);

        final updatedPool = PrizePoolModel(
          id: activePool.id,
          totalAmount: activePool.totalAmount + amount,
          participantCount: activePool.participantCount + 1,
          distributionDate: activePool.distributionDate,
          isDistributed: false,
        );

        await _prizePoolsCollection.doc(poolId).update(updatedPool.toMap());
      }
    }
  }

  PrizePoolModel _createNewPrizePool(double initialAmount) {
    final now = DateTime.now();
    final distributionDate = now.add(const Duration(days: 7));

    String poolId;
    if (_demoMode) {
      poolId = 'demo-pool-${_prizePools.length + 1}';
    } else {
      // In Firebase mode, use a timestamp-based ID
      poolId = 'pool-${now.millisecondsSinceEpoch}';
    }

    final newPool = PrizePoolModel(
      id: poolId,
      totalAmount: initialAmount,
      participantCount: 1,
      distributionDate: distributionDate,
      isDistributed: false,
    );

    if (_demoMode) {
      _prizePools.add(newPool);
    }

    return newPool;
  }

  Future<List<PrizePoolModel>> getPrizePools() async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Sort by distribution date, descending
      final sortedPools = List<PrizePoolModel>.from(_prizePools);
      sortedPools.sort(
        (a, b) => b.distributionDate.compareTo(a.distributionDate),
      );

      return sortedPools;
    } else {
      // In Firebase mode, get from Firestore
      final QuerySnapshot snapshot =
          await _prizePoolsCollection
              .orderBy('distributionDate', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PrizePoolModel.fromMap(data, doc.id);
      }).toList();
    }
  }

  Future<void> distributePrizePool(String poolId) async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // Get the prize pool
      final index = _prizePools.indexWhere((pool) => pool.id == poolId);
      if (index < 0) return;

      final pool = _prizePools[index];
      if (pool.isDistributed) return; // Already distributed

      // Get all users who watched ads
      final eligibleUsers =
          _users.values.where((user) => user.adWatchCount > 0).toList();

      final prizePerUser = pool.prizePerParticipant;

      // Distribute the prize to each user
      for (final user in eligibleUsers) {
        final updatedUser = user.copyWith(
          earnings: user.earnings + prizePerUser,
        );

        _users[user.uid] = updatedUser;
      }

      // Mark the prize pool as distributed
      _prizePools[index] = PrizePoolModel(
        id: pool.id,
        totalAmount: pool.totalAmount,
        participantCount: pool.participantCount,
        distributionDate: pool.distributionDate,
        isDistributed: true,
      );
    } else {
      // In Firebase mode
      // Get the prize pool from Firestore
      final DocumentSnapshot doc =
          await _prizePoolsCollection.doc(poolId).get();
      if (!doc.exists) return;

      final poolData = doc.data() as Map<String, dynamic>;
      final pool = PrizePoolModel.fromMap(poolData, poolId);

      if (pool.isDistributed) return; // Already distributed

      // Get all users who watched ads from Firestore
      final QuerySnapshot usersSnapshot =
          await _usersCollection.where('adWatchCount', isGreaterThan: 0).get();

      final prizePerUser = pool.prizePerParticipant;

      // Distribute the prize to each user
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data() as Map<String, dynamic>;
        final user = UserModel.fromMap(userData, userId);

        final updatedUser = user.copyWith(
          earnings: user.earnings + prizePerUser,
        );

        await _usersCollection.doc(userId).update(updatedUser.toMap());
      }

      // Mark the prize pool as distributed
      await _prizePoolsCollection.doc(poolId).update({'isDistributed': true});
    }
  }

  // Check if user can watch an ad today
  Future<bool> canWatchAdToday(String userId) async {
    if (_demoMode) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In demo mode, if the user is not in the map yet, we'll assume they can watch an ad
      final user = _users[userId];
      if (user == null) return true;

      final now = DateTime.now();
      final lastWatch = user.lastAdWatchTime;

      // Check if the last watch was on a different day
      return now.day != lastWatch.day ||
          now.month != lastWatch.month ||
          now.year != lastWatch.year;
    } else {
      // In Firebase mode
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return true; // New users can watch an ad

      final userData = userDoc.data() as Map<String, dynamic>;
      final user = UserModel.fromMap(userData, userId);

      final now = DateTime.now();
      final lastWatch = user.lastAdWatchTime;

      // Check if the last watch was on a different day
      return now.day != lastWatch.day ||
          now.month != lastWatch.month ||
          now.year != lastWatch.year;
    }
  }
}
