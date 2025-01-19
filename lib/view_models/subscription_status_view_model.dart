import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final subscriptionStatusProvider = StateNotifierProvider<SubscriptionStatusViewModel, String>(
      (ref) => SubscriptionStatusViewModel(),
);

class SubscriptionStatusViewModel extends StateNotifier<String> {
  static const String free = 'free';
  static const String basic = 'basic';
  static const String premium = 'premium';

  SubscriptionStatusViewModel() : super(free) {
    loadStatus(); // 起動時に保存された課金状態をロード
  }

  // 課金状態を保存
  Future<void> saveStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', status);
    state = status; // 状態を更新
  }

  // 課金状態をロード
  Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('subscription_plan') ?? free; // 保存された状態をロード
  }

  // UI関連のロジック例
  bool isPremium() => state == premium;

  bool isBasic() => state == basic;

  bool isFree() => state == free;

  String getDisplayMessage() {
    if (state == premium) {
      return "プレミアムプランに加入中です";
    } else if (state == basic) {
      return "ベーシックプランに加入中です";
    } else {
      return "現在、無料プランをご利用中です";
    }
  }
}
