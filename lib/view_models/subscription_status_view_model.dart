import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'dart:io';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

final subscriptionStatusProvider =
StateNotifierProvider<SubscriptionStatusViewModel, String>(
      (ref) => SubscriptionStatusViewModel(ref),
);

class SubscriptionStatusViewModel extends StateNotifier<String> {
  static const String free = 'free';
  static const String basic = 'basic';
  static const String premium = 'premium';
  static const String cancellationPending = 'cancellation_pending';
  bool _isCancellingProcessing = false;  // 退会処理中フラグ

  late final InAppPurchase _inAppPurchase;
  final Ref ref;
  String? currentPlanId;

  SubscriptionStatusViewModel(this.ref) : super(free) {
    _inAppPurchase = InAppPurchase.instance;
    _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => print('[DEBUG] Purchase Stream Done'),
      onError: (error) {
        print('[ERROR] Purchase Stream Error: $error');
      },
    );
    loadStatus();
  }

  Future<void> loadStatus() async {
    final sp = await SharedPreferences.getInstance();
    final loadedValue = sp.getString('subscription_plan') ?? free;
    currentPlanId = loadedValue;
    print('[DEBUG] loadStatus => loadedValue=$loadedValue');
    await syncWithFirebase();
  }

  void setSubscriptionStatus(String status) {
    state = status;
  }

  Future<void> syncWithFirebase() async {
    // SharedPreferences からローカルの購読状態を取得
    final sp = await SharedPreferences.getInstance();
    final localState = sp.getString('subscription_plan') ?? free;
    print('[DEBUG] syncWithFirebase - local state: $localState');

    // ユーザーが未ログインの場合は同期処理をスキップ
    if (FirebaseAuth.instance.currentUser == null) {
      print('[DEBUG] syncWithFirebase - ユーザー未ログインのため、同期をスキップします。');
      state = localState;
      currentPlanId = localState;
      return;
    }

    final firebaseRepo = ref.read(firebaseRepositoryProvider);
    final firebasePlan = await firebaseRepo.fetchSubscriptionPlan();
    print('[DEBUG] syncWithFirebase - Firebase plan: $firebasePlan');

    // Firebaseから値がある場合のみローカルを更新、nullの場合はローカル状態をそのまま維持
    if (firebasePlan != null) {
      await sp.setString('subscription_plan', firebasePlan);
      state = firebasePlan;
      currentPlanId = firebasePlan;
      print('[DEBUG] syncWithFirebase - Updated local state to: $firebasePlan');
    } else {
      state = localState;
      currentPlanId = localState;
      print('[DEBUG] syncWithFirebase - Firebase plan is null, preserving local state: $localState');
    }

    print('[DEBUG] syncWithFirebase - Final shared_preferences: ${sp.getString('subscription_plan')}');
    print('[DEBUG] syncWithFirebase - Final state: $state');
  }

  // 退会処理中フラグをセットするメソッド（外部からも呼び出せるようにする場合）
  void setCancellingProcessing(bool value) {
    _isCancellingProcessing = value;
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    // 退会処理中なら購入イベントは無視する
    if (_isCancellingProcessing) {
      print('[DEBUG] 退会処理中のため、purchaseStream のイベントを無視します。');
      return;
    }
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print("課金処理中:${purchaseDetails.productID}");
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _handlePurchaseSuccess(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print("課金エラー:${purchaseDetails.error}");
        _handlePurchaseError(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handleCancellation() async {
    final subscriptionNotifier = ref.read(subscriptionStatusProvider.notifier);
    // 退会処理開始前にフラグを立てる
    subscriptionNotifier.setCancellingProcessing(true);

    final firebaseRepo = ref.read(firebaseRepositoryProvider);
    try {
      await firebaseRepo.markUserAsUnsubscribed();
      await subscriptionNotifier.saveStatus(SubscriptionStatusViewModel.free);
      print('[DEBUG] _handleCancellation => set status to free');
    } catch (e) {
      print('[ERROR] _handleCancellation error: $e');
      // エラーハンドリング（必要に応じて）
    } finally {
      // 退会処理が完了したら、一定時間後またはすぐにフラグをクリアする
      Future.delayed(Duration(seconds: 2), () {
        subscriptionNotifier.setCancellingProcessing(false);
        print('[DEBUG] 退会処理完了、フラグをクリア');
      });
    }
  }


  Future<bool> _isPurchased(String planId) async {
    final sp = await SharedPreferences.getInstance();
    final currentPlan = sp.getString('subscription_plan');
    return currentPlan == planId;
  }

  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    final pid = purchaseDetails.productID;
    String planId = free;
    if (pid == 'com.gappson56.yosandekakeibo.basicPlan') {
      planId = basic;
    } else if (pid == 'com.gappson56.yosandekakeibo.premiumPlan') {
      planId = premium;
    }

    // もし復元イベント（restored）なら強制更新を行う
    if (purchaseDetails.status == PurchaseStatus.restored) {
      // Firebaseへの更新（ログイン状態なら）
      if (FirebaseAuth.instance.currentUser != null) {
        final firebaseRepo = ref.read(firebaseRepositoryProvider);
        try {
          await firebaseRepo.markUserAsSubscribed(planId);
          print('[DEBUG] (Restore) Firebase上のサブスクリプション状態を更新しました: $planId');
        } catch (e) {
          print('[ERROR] markUserAsSubscribed (restore) 失敗: $e');
        }
      } else {
        print('[WARN] ユーザーがログインしていないため、Firebaseへの更新はスキップします。');
      }
      // force:true で状態更新（これにより cancellation_pending のガードを回避）
      await saveStatus(planId, force: true);
      print("課金プラン (restored): $planId に強制更新");
      return;
    }

    // 通常の購入の場合、現在が cancellation_pending なら更新を無視する
    if (purchaseDetails.status == PurchaseStatus.purchased &&
        state == cancellationPending) {
      print('[DEBUG] _handlePurchaseSuccess: 現在 cancellation_pending 状態のため、購入更新は無視します。');
      return;
    }

    // 既に同じプランなら何もしない
    if (await _isPurchased(planId)) {
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
      return;
    }

    // 通常の更新処理
    await saveStatus(planId);
    print("課金プラン:$planId に更新");

    if (FirebaseAuth.instance.currentUser != null) {
      final firebaseRepo = ref.read(firebaseRepositoryProvider);
      try {
        await firebaseRepo.markUserAsSubscribed(planId);
      } catch (e) {
        print('[ERROR] _handlePurchaseSuccess - markUserAsSubscribed error: $e');
      }
    } else {
      print('[WARN] ユーザーがログインしていないため、Firebaseへの更新はスキップします。');
    }
  }


  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.error == null) {
      return;
    }

    if (Platform.isAndroid && purchaseDetails is GooglePlayPurchaseDetails) {
      if (purchaseDetails.error!.code == "userCancelled") {
        print('[DEBUG] User cancelled the purchase on Android (Unified)');
        _handleCancellation();
      }
    }

    if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
      if (purchaseDetails.error!.code == "paymentCancelled") {
        print('[DEBUG] User cancelled the purchase on iOS (Unified)');
        _handleCancellation();
      }
    }

    if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
      if (purchaseDetails.error!.code == "storekit_duplicate_product_object") {
        print('[ERROR] Duplicate product object error. Trying to complete purchase...');
      }
    }
    print('[ERROR] Unhandled purchase error: ${purchaseDetails.error}');

    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  bool get isCancellationPending => state == cancellationPending;

  Future<bool> isCancellationPendingCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final spPlan = prefs.getString('subscription_plan');
    return spPlan == cancellationPending;
  }

  Future<void> saveStatus(String status, {bool force = false}) async {
    print('[DEBUG] saveStatus called with status=$status, force=$force');
    // force==false の場合のみ、現在が cancellation_pending なら basic への更新を無視する
    if (!force && state == cancellationPending && status == basic) {
      print('[DEBUG] saveStatus: 現在 cancellation_pending 状態のため、basic への更新を無視します。');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', status);
    state = status;
    currentPlanId = status;
    print('[DEBUG] saveStatus: state を $state に更新しました。');
  }



  void updateStatus(String newStatus, WidgetRef ref) {
    state = newStatus;
    currentPlanId = newStatus;
    if (newStatus == free) {
      ref.read(settingsViewModelProvider.notifier).resetToDefaultSettings();
    }
  }

  Future<void> resetToFree() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseRepo = ref.read(firebaseRepositoryProvider);

    try {
      await firebaseRepo.markUserAsUnsubscribed();
    } catch (e) {
      print('[ERROR] resetToFree - markUserAsUnsubscribed error: $e');
      // エラーハンドリング（必要に応じて）
    }

    await prefs.clear();
    await prefs.setString('subscription_plan', free);

    state = free;
    currentPlanId = free;
    print('[DEBUG] Reset to free');
  }

  bool isPremium() => state == premium;
  bool isPaidUser() => state == premium || state == basic;
  bool isFree() => state == free;

  String getDisplayMessage() {
    if (state == premium) {
      return "プレミアムプランに加入中です";
    } else if (state == basic) {
      return "ベーシックプランに加入中です";
    } else if (state == cancellationPending) {
      return "退会処理中(次回更新まで有効)";
    } else {
      return "現在、無料プランをご利用中です";
    }
  }
}
