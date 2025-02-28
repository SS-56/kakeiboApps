import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';

final subscriptionStatusProvider = StateNotifierProvider<SubscriptionStatusViewModel, String>(
      (ref) => SubscriptionStatusViewModel(),
);

class SubscriptionStatusViewModel extends StateNotifier<String> {
  static const String free = 'free';
  static const String basic = 'basic';
  static const String premium = 'premium';

  SubscriptionStatusViewModel() : super(free) {
    print('[DEBUG] SubscriptionStatusViewModel constructor => initial state=free');
    loadStatus(); // 起動時に保存された課金状態をロード
  }

  // 課金状態を保存
  Future<void> saveStatus(String status) async {
    print('[DEBUG] saveStatus called with status=$status');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', status);
    print('[DEBUG] loadStatus => loadedValue=$loadStatus');
    state = status; // 状態を更新
    print('[DEBUG] loadStatus => new state=$state');
  }

  // 課金状態をロード
  Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('subscription_plan') ?? free; // 保存された状態をロード
    print('[DEBUG] loadStatus => from the actual file in subscription_status_view_model.dart, loadedValue=$state');
  }

  void updateStatus(String newStatus, WidgetRef ref) {
    state = newStatus;

    // ★ 追加: 課金プラン解除 (freeに変化) になったら Settings を初期化
    if (newStatus == 'free') {
      ref.read(settingsViewModelProvider.notifier).resetToDefaultSettings();
    }
  }

  // UI関連のロジック例
  bool isPremium() => state == premium;

  bool isPaidUser() => state == premium || state == basic;

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
