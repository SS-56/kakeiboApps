// ファイル名: lib/views/notifiers/user_status_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isPremiumProvider = StateNotifierProvider<UserStatusNotifier, String>(
      (ref) => UserStatusNotifier(),
);

Future<void> saveSubscriptionState(String plan) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('subscription_plan', plan);
}

Future<String> loadSubscriptionState() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('subscription_plan') ?? 'free';
}

class UserStatusNotifier extends StateNotifier<String> {
  UserStatusNotifier() : super("free") {
    _loadPremiumStatus(); // 起動時に保存された課金状態をロード
  }

  // 課金状態を保存
  Future<void> savePremiumStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('premium_status', status);
    state = status; // 状態を更新
  }

  // 課金状態をロード
  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('premium_status') ?? "free"; // 保存された状態をロード
  }
}
