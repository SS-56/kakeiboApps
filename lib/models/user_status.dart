class UserStatus {
  final String subscriptionPlan; // "free", "basic", "premium"
  final bool isPremium; // プレミアムユーザーかどうか
  final DateTime lastUpdated; // 最終更新日時

  UserStatus({
    required this.subscriptionPlan,
    required this.isPremium,
    required this.lastUpdated,
  });

  /// 無料ユーザーの状態を生成
  factory UserStatus.free() {
    return UserStatus(
      subscriptionPlan: "free",
      isPremium: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// ベーシックユーザーの状態を生成
  factory UserStatus.basic() {
    return UserStatus(
      subscriptionPlan: "basic",
      isPremium: false,
      lastUpdated: DateTime.now(),
    );
  }

  /// プレミアムユーザーの状態を生成
  factory UserStatus.premium() {
    return UserStatus(
      subscriptionPlan: "premium",
      isPremium: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// JSON に変換
  Map<String, dynamic> toJson() {
    return {
      'subscriptionPlan': subscriptionPlan,
      'isPremium': isPremium,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// JSON から生成
  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      subscriptionPlan: json['subscriptionPlan'] as String,
      isPremium: json['isPremium'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}
