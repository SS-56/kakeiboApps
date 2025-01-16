class UserStatus {
  final String subscriptionPlan; // 'free', 'basic', 'premium'
  final bool isPremium; // プレミアムステータス
  final DateTime lastUpdated; // 最終更新日時

  UserStatus({
    required this.subscriptionPlan,
    this.isPremium = false,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'subscriptionPlan': subscriptionPlan,
      'isPremium': isPremium,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  static UserStatus fromJson(Map<String, dynamic> json) {
    return UserStatus(
      subscriptionPlan: json['subscriptionPlan'],
      isPremium: json['isPremium'] ?? false,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
