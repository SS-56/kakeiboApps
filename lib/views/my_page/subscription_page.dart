import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'
    show AppStorePurchaseDetails, InAppPurchaseStoreKitPlatform, InAppPurchaseStoreKitPlatformAddition;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  SubscriptionPageState createState() => SubscriptionPageState();
}

class SubscriptionPageState extends ConsumerState<SubscriptionPage>
    with WidgetsBindingObserver {
  bool _isUnsubscribing = false;
  late final InAppPurchase _inAppPurchase;
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final Map<String, String> _storeProductIds = {
    "basic": "com.gappson56.yosandekakeibo.basicPlan",
    "premium": "com.gappson56.yosandekakeibo.premiumPlan",
  };

  @override
  void initState() {
    super.initState();
    _inAppPurchase = InAppPurchase.instance;
    _subscription = _inAppPurchase.purchaseStream.listen(_listenToPurchaseUpdated,
        onDone: () => print('[DEBUG] Purchase stream closed'),
        onError: (error) => print('[ERROR] Purchase stream error: $error'));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await ref.read(subscriptionStatusProvider.notifier).syncWithFirebase();
    await _loadProducts(); // InAppPurchase の初期化後に呼び出す

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkSubscriptionStatus();
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print("ストアが利用できません");
      setState(() {
        _products = [];
        _isLoading = false;
      });
      return;
    }
    final response =
    await _inAppPurchase.queryProductDetails(_storeProductIds.values.toSet());
    if (response.error != null) {
      print("課金アイテム取得失敗:${response.error}");
      setState(() {
        _products = [];
        _isLoading = false;
      });
      UIUtils.showErrorDialog(
          context, "課金アイテムの取得に失敗しました: ${response.error}");
      return;
    }
    if (response.productDetails.isEmpty) {
      print("課金アイテムが見つかりません");
      setState(() {
        _products = [];
        _isLoading = false;
      });
      UIUtils.showErrorDialog(context, "課金アイテムが見つかりません。");
      return;
    }
    setState(() {
      _products = response.productDetails;
      _isLoading = false;
    });
    print("取得したアイテム: $_products");
  }

  Future<void> _checkSubscriptionStatus() async {
    await ref.read(subscriptionStatusProvider.notifier).syncWithFirebase();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
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

  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.error == null) return;
    if (Platform.isAndroid && purchaseDetails is GooglePlayPurchaseDetails) {
      if (purchaseDetails.error!.code == "userCancelled") {
        print('[DEBUG] User cancelled the purchase on Android (Unified)');
        _handleCancellation();
        return;
      }
    }
    if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
      if (purchaseDetails.error!.code == "paymentCancelled") {
        print('[DEBUG] User cancelled the purchase on iOS (Unified)');
        _handleCancellation();
        return;
      }
    }
    if (Platform.isIOS && purchaseDetails is AppStorePurchaseDetails) {
      if (purchaseDetails.error!.code == "storekit_duplicate_product_object") {
        print('[ERROR] Duplicate product object error. Trying to complete purchase...');
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
        return;
      }
    }
    print('[ERROR] Unhandled purchase error: ${purchaseDetails.error}');
  }

  Future<void> _handleCancellation() async {
    final firebaseRepo = ref.read(firebaseRepositoryProvider);
    await firebaseRepo.markUserAsUnsubscribed();
    await ref.read(subscriptionStatusProvider.notifier)
        .saveStatus(SubscriptionStatusViewModel.free);
    print('[DEBUG] _handleCancellation => set status to free');
  }

  bool _isRestoring = false;

  void _restorePurchases() {
    if (_isRestoring) return; // すでに復元中なら何もしない
    _isRestoring = true;

    _inAppPurchase.restorePurchases();

    // ここでは復元開始直後に一度だけフィードバックを表示するか、
    // または _handlePurchaseSuccess 内で1回だけ表示するようにする
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("購入の復元を開始しました")),
    );
  }


  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    final pid = purchaseDetails.productID;
    String planId = "free";
    _storeProductIds.forEach((key, val) {
      if (val == pid) {
        planId = key;
      }
    });

    // もし復元処理中なら強制的に更新する
    if (_isRestoring) {
      try {
        await ref.read(firebaseRepositoryProvider).markUserAsSubscribed(planId);
        print('[DEBUG] (Restore) Firebase上のサブスクリプション状態を更新しました: $planId');
      } catch (e) {
        print('[ERROR] markUserAsSubscribed (restore) 失敗: $e');
      }
      await ref.read(subscriptionStatusProvider.notifier).saveStatus(planId);
      print("課金プラン (restore): $planId に更新");
      _isRestoring = false;
      return;
    }

    // 通常の購入の場合は、退会処理中なら更新を無視する
    if (purchaseDetails.status == PurchaseStatus.purchased &&
        ref.read(subscriptionStatusProvider) == SubscriptionStatusViewModel.cancellationPending) {
      print('[DEBUG] _handlePurchaseSuccess: cancellation_pending 状態のため、購入更新は無視します。');
      return;
    }

    // 通常の状態更新
    await ref.read(subscriptionStatusProvider.notifier).saveStatus(planId);
    print("課金プラン:$planId に更新");
  }


  Future<void> _startPurchase(String planId) async {
    final productId = _storeProductIds[planId];
    if (productId == null) {
      UIUtils.showErrorDialog(context, "課金アイテムが設定されていません($planId)");
      return;
    }
    if (_products.isEmpty) {
      UIUtils.showErrorDialog(context, "課金アイテムが読み込まれていません。");
      return;
    }
    // 退会処理中の場合は処理せず、ダイアログを表示
    if (ref.read(subscriptionStatusProvider) == SubscriptionStatusViewModel.cancellationPending) {
      UIUtils.showErrorDialog(context, "退会処理中につき、月次処理最終日までは有料機能が使えます。");
      return;
    }
    final product = _products.firstWhere(
          (p) => p.id == productId,
      orElse: () => throw Exception("該当productなし:$productId"),
    );
    final purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _unsubscribePlan(WidgetRef ref, String planId) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("確認"),
          content: const Text("本当に退会しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("退会する"),
            ),
          ],
        );
      },
    );
    if (result == false) return;
    setState(() {
      _isUnsubscribing = true;
    });
    try {
      await ref.read(subscriptionStatusProvider.notifier)
          .saveStatus(SubscriptionStatusViewModel.cancellationPending);
      await _navigateToSubscriptionManagement();
    } catch (e) {
      print("[ERROR] unsubscribePlan failed: $e");
      UIUtils.showErrorDialog(context, "退会処理中にエラーが発生しました: $e");
    } finally {
      setState(() {
        _isUnsubscribing = false;
      });
    }
  }

  Future<void> _navigateToSubscriptionManagement() async {
    final url = (Platform.isIOS)
        ? "https://apps.apple.com/account/subscriptions"
        : "https://play.google.com/store/account/subscriptions";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = ref.watch(subscriptionStatusProvider);
    final isCancelling = ref.watch(subscriptionStatusProvider.notifier).isCancellationPending;
    final currentPlanId = ref.watch(subscriptionStatusProvider.notifier).currentPlanId;

    // プランリスト（価格をハードコード）
    final List<Map<String, dynamic>> plans = [
      {
        "id": "basic",
        "title": "ベーシックプラン",
        "price":100,
        "description": """
・各金額カードをタップしてメモや編集が可能
・浪費スイッチでマイページに浪費額を表示
・固定費に「貯金」と入力すれば
　貯金額をマイページで表示
・貯金額の目標を設定可能
・月次データをクラウドに24ヶ月保存
""",
        "isDev": false,
      },
      {
        "id": "premium",
        "title": "プレミアムプラン",
        "price":300,
        "description": """
・収入/固定費/使った金額の種類をアイコン切替可
・支出額全体を種類別にグラフ化して分析
・カメラでレシート撮影して金額を自動入力
・コンシェルジュ機能で家計管理をサポート
""",
        "isDev": true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("サブスクリプション\n(月額課金プラン)"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () async {
                    await _loadProducts();
                    if (_products.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('商品情報を更新しました')),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh),
                ),
                TextButton(
                  onPressed: () {
                    _restorePurchases();
                  },
                  child: const Text(
                    "購入の復元",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 「購入の復元」は表示しない
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              ref.watch(subscriptionStatusProvider.notifier).getDisplayMessage(),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            for (final plan in plans)
              _buildPlanCard(
                context,
                ref,
                planId: plan["id"] as String,
                planTitle: plan["title"] as String,
                price: plan["price"] as int,
                description: plan["description"] as String,
                isDev: plan["isDev"] as bool,
                currentPlanId: currentPlanId,
                isCancelling: isCancelling,
              ),
            const SizedBox(height: 24), // カード間のスペース
            // Apple 標準利用規約 (EULA) カード
            Card(
              child: ListTile(
                title: const Text("Apple 標準利用規約 (EULA)"),
                onTap: () async {
                  final url = Uri.parse("https://www.apple.com/legal/internet-services/terms/site.html");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    print("Apple 標準利用規約のリンクを開けませんでした");
                    // エラー表示 (例: SnackBar) を追加しても良い
                    if (context.mounted) { //非同期処理後のcontextチェック
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('リンクを開けませんでした')),
                      );
                    }
                  }
                },
              ),
            ),
            // プライバシーポリシーカード
            Card(
              child: ListTile(
                title: const Text("プライバシーポリシー"),
                onTap: () async {
                  final url = Uri.parse("https://sites.google.com/view/gappson");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    print("リンクを開けませんでした");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('リンクを開けませんでした')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context,
      WidgetRef ref, {
        required String planId,
        required String planTitle,
        required int price,
        required String description,
        required bool isDev,
        required String? currentPlanId,
        required bool isCancelling,
      }) {
    // 現在加入中かどうか
    final bool isCurrent = (currentPlanId == planId);
    // 現在の購読状態
    final subscriptionState = ref.watch(subscriptionStatusProvider);

    print("[DEBUG] _buildPlanCard - planId: $planId, currentPlanId: $currentPlanId, isCurrent: $isCurrent, isDev: $isDev, subscriptionState: $subscriptionState");

    String buttonLabel;
    VoidCallback? onPressed;

    if (isDev) {
      // プレミアムプランは常に選択できません
      buttonLabel = "選択できません";
      onPressed = null;
    } else {
      // ベーシックプランの場合
      if (isCurrent) {
        if (subscriptionState == SubscriptionStatusViewModel.cancellationPending) {
          // 加入中かつ退会処理中の場合：カード内タイトル直下に赤字で状態を表示し、ボタンを押すとダイアログで案内
          buttonLabel = "退会処理中";
          onPressed = () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("お知らせ"),
                  content: const Text("退会処理中につき、月次処理最終日までは有料機能が使えます。"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          };
        } else {
          buttonLabel = "退会する";
          onPressed = () => _unsubscribePlan(ref, planId);
        }
      } else {
        // 退会処理中はボタンラベルを「退会処理中」に設定
        if (isCancelling) {
          buttonLabel = "退会処理中";
          onPressed = () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("お知らせ"),
                  content: const Text("退会処理中【次回更新まで有料機能を使えます】"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                );
              },
            );
          };
        } else {
          buttonLabel = "選択する";
          onPressed = () {
            if (_products.isEmpty) {
              UIUtils.showErrorDialog(
                  context, "課金アイテムを読み込み中です。しばらくお待ちください。");
            } else {
              _startPurchase(planId);
            }
          };
        }
      }
    }

    return Card(
      color: isCurrent ? Colors.lime[50] : null,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プランタイトル
            Text(
              planTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // ベーシックプラン：加入中の場合、カード内に状態表示
            if (!isDev && isCurrent)
              Text(
                subscriptionState == SubscriptionStatusViewModel.cancellationPending
                    ? "退会処理中【次回更新まで有効】"
                    : "現在加入中のプランです",
                style: const TextStyle(color: Colors.red),
              ),
            if (!isDev && isCurrent) const SizedBox(height: 8),
            // プラン説明
            if (isDev)
              const Text(
                "(現在開発中 近日リリース予定です)",
                style: TextStyle(color: Colors.red),
              ),
            Text(description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),

            if (!isDev)
            Text("¥${price.toString()} / 月",
              style: const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:Colors.green),
            ),
            const SizedBox(height:8),

            if (!isDev)
            // 価格表示
            Text(
              "1ヶ月ごとに自動更新されます",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            // ボタン
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _isUnsubscribing ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent ? Colors.grey : null,
                ),
                child: Text(buttonLabel, style: TextStyle(color: Colors.cyan[800]),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

