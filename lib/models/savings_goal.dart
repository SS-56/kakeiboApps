class SavingsGoal {
  final double goalAmount; // 目標貯金額
  final DateTime targetDate; // 達成目標日
  final bool isAchieved; // 達成済みかどうか

  SavingsGoal({
    required this.goalAmount,
    required this.targetDate,
    this.isAchieved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'goalAmount': goalAmount,
      'targetDate': targetDate.toIso8601String(),
      'isAchieved': isAchieved,
    };
  }

  static SavingsGoal fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      goalAmount: (json['goalAmount'] as num).toDouble(),
      targetDate: DateTime.parse(json['targetDate']),
      isAchieved: json['isAchieved'] ?? false,
    );
  }
}
