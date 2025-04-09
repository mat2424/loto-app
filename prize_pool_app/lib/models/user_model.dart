class UserModel {
  final String uid;
  final String email;
  final String username;
  final int adWatchCount;
  final double earnings;
  final DateTime lastAdWatchTime;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.adWatchCount = 0,
    this.earnings = 0.0,
    DateTime? lastAdWatchTime,
  }) : lastAdWatchTime = lastAdWatchTime ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      adWatchCount: data['adWatchCount'] ?? 0,
      earnings: (data['earnings'] ?? 0.0).toDouble(),
      lastAdWatchTime: data['lastAdWatchTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastAdWatchTime'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'adWatchCount': adWatchCount,
      'earnings': earnings,
      'lastAdWatchTime': lastAdWatchTime.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    int? adWatchCount,
    double? earnings,
    DateTime? lastAdWatchTime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      adWatchCount: adWatchCount ?? this.adWatchCount,
      earnings: earnings ?? this.earnings,
      lastAdWatchTime: lastAdWatchTime ?? this.lastAdWatchTime,
    );
  }
}
