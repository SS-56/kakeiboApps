import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';

final subscriptionStatusProvider = StateNotifierProvider<SubscriptionStatusViewModel, String>(
      (ref) => SubscriptionStatusViewModel(),
);

class SubscriptionStatusViewModel extends StateNotifier<String> {
  // === 既存の定数 ===
  static const String free = 'free';
  static const String basic = 'basic';
  static const String premium = 'premium';

  // 退会処理中ステータス
  static const String cancellationPending = 'cancellation_pending';

  late final InAppPurchase _inAppPurchase;
  bool _hasActivePlan = false;

  SubscriptionStatusViewModel() : super(free) {
    print('[DEBUG] SubscriptionStatusViewModel constructor => initial state=free');

    _inAppPurchase = InAppPurchase.instance;

    // ★ 購入ストリームをリッスン (ここが重要)
    _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => print('[DEBUG] Purchase Stream Done'),
      onError: (error) {
        print('[ERROR] Purchase Stream Error: $error');
      },
    );

    // 起動時に保存された課金状態をロード
    loadStatus();
  }

  /// 起動時に保存された課金状態をロード
  Future<void> loadStatus() async {
    final sp = await SharedPreferences.getInstance();
    final loadedValue = sp.getString('subscription_plan') ?? free;

    print('[DEBUG] loadStatus => loadedValue=$loadedValue');

    /*
    // ★★★ 修正: _checkPastPurchasesEmpty() を呼び出す部分をコメントアウト ★★★
    // final noSubscriptionOnStore = await _checkPastPurchasesEmpty();
    // if (noSubscriptionOnStore) {
    //   // ストアに契約なし => 常にfree優先
    //   state = 'free';
    //   await sp.setString('subscription_plan', 'free');
    //   return;
    // }
    */

    // 既存のロジックを尊重し、_hasActivePlanは後段の購入処理で更新
    state = loadedValue;
  }

  /// 課金ストリームからのイベントをハンドリング
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('[DEBUG] Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {

        // ★ もし現在のステータスが "cancellation_pending" なら無視
        if (state == cancellationPending) {
          print('[DEBUG] Status is cancellation_pending -> ignore event');
          continue;
        }

        _hasActivePlan = true;

        // productID → planId 変換
        String planId = free;
        if (purchaseDetails.productID == 'com.gappson56.yosandekakeibo.basicPlan') {
          planId = basic;
        } else if (purchaseDetails.productID == 'com.gappson56.yosandekakeibo.premiumPlan') {
          planId = premium;
        }

        print('[DEBUG] Purchase success: $planId');
        saveStatus(planId);

      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('[ERROR] Purchase error: ${purchaseDetails.error?.message}');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // /// 【既存コード・文言は削除しない】 .queryPastPurchases() が未定義ならビルドエラーになるため、呼び出しをコメントアウト済
  // Future<bool> _checkPastPurchasesEmpty() async {
  //   final bool isAvailable = await InAppPurchase.instance.isAvailable();
  //   if (!isAvailable) {
  //     // ストアが利用不可なら判断不能 -> false(契約無いと断言できない)
  //     return false;
  //   }
  //   try {
  //     final qpp = await InAppPurchase.instance.queryPastPurchases();
  //     if (qpp.error != null) {
  //       // 取得エラー -> false(断言できない)
  //       return false;
  //     }
  //     // 「全く購入履歴がない」 => true
  //     return qpp.pastPurchases.isEmpty;
  //   } catch (e) {
  //     print('[ERROR] queryPastPurchases failed or not found: $e');
  //     return false;
  //   }
  // }

  // 課金状態を保存
  Future<void> saveStatus(String status) async {
    print('[DEBUG] saveStatus called with status=$status');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', status);
    print('[DEBUG] loadStatus => loadedValue=$loadStatus');
    state = status; // 状態を更新
    print('[DEBUG] loadStatus => new state=$state');
  }

  void updateStatus(String newStatus, WidgetRef ref) {
    state = newStatus;

    // ★ 既存機能: もしfreeになったらSettingsを初期化
    if (newStatus == free) {
      ref.read(settingsViewModelProvider.notifier).resetToDefaultSettings();
    }
  }

  // 全データをリセットして free に戻す
  Future<void> resetToFree() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear(); // 全データ削除
    await prefs.setString('subscription_plan', free);

    state = free;
    print('[DEBUG] Reset to free');
  }

  // UI関連のロジック例 (既存)
  bool isPremium() => state == premium;
  bool isPaidUser() => state == premium || state == basic;
  bool isFree() => state == free;

  // 退会処理中判定
  bool isCancellationPending() => state == cancellationPending;

  String getDisplayMessage() {
    if (state == premium) {
      return "プレミアムプランに加入中です";
    } else if (state == basic) {
      return "ベーシックプランに加入中です";
    } else if (state == cancellationPending) {
      return "退会処理中(次回更新まで有効)";
    } else {
      // free
      return "現在、無料プランをご利用中です";
    }
  }
}
