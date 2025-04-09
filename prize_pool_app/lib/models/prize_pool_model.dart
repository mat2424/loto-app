class PrizePoolModel {
  final String id;
  final double totalAmount;
  final int participantCount;
  final DateTime distributionDate;
  final bool isDistributed;

  PrizePoolModel({
    required this.id,
    required this.totalAmount,
    required this.participantCount,
    required this.distributionDate,
    this.isDistributed = false,
  });

  factory PrizePoolModel.fromMap(Map<String, dynamic> data, String id) {
    return PrizePoolModel(
      id: id,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      participantCount: data['participantCount'] ?? 0,
      distributionDate: data['distributionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['distributionDate'])
          : DateTime.now().add(const Duration(days: 7)),
      isDistributed: data['isDistributed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAmount': totalAmount,
      'participantCount': participantCount,
      'distributionDate': distributionDate.millisecondsSinceEpoch,
      'isDistributed': isDistributed,
    };
  }

  double get prizePerParticipant {
    if (participantCount == 0) return 0.0;
    return totalAmount / participantCount;
  }
}
