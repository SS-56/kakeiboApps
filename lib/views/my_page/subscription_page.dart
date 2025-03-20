import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'
    show InAppPurchaseStoreKitPlatform, InAppPurchaseStoreKitPlatformAddition;

// 【追加】Android専用の詳細クラスを使うためにインポートが必要
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yosan_de_kakeibo/utils/ui_utils.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  SubscriptionPageState createState() => SubscriptionPageState();
}

class SubscriptionPageState extends ConsumerState<SubscriptionPage>
    with WidgetsBindingObserver {
  // 課金インスタンス
  late final InAppPurchase _inAppPurchase;
  // 課金ストリームの購読
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  // プロダクト一覧
  List<ProductDetails> _products = [];

  // サブスクが有効かどうかの一時フラグ
  bool _hasActivePlan = false;

  // iOS/Android共通で使うストアID
  final Map<String, String> _storeProductIds = {
    "basic": "com.gappson56.yosandekakeibo.basicPlan",
    "premium": "com.gappson56.yosandekakeibo.premiumPlan",
  };

  @override
  void initState() {
    super.initState();
    // ライフサイクル監視
    WidgetsBinding.instance.addObserver(this);

    if (Platform.isIOS) {
      // iOSでStoreKit2を使う
      InAppPurchaseStoreKitPlatform.registerPlatform();
    }

    _inAppPurchase = InAppPurchase.instance;

    // 課金ストリーム購読
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
          (purchases) => _listenToPurchaseUpdated(purchases),
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        UIUtils.showErrorDialog(context, "課金ストリームエラー: $error");
      },
    );

    // プロダクト読み込み
    _loadProducts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  // フォアグラウンド復帰時にサブスクチェック
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkSubscriptionStatus();
    }
  }

  // ストア使用可かどうか + productId問い合わせ
  Future<void> _loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print("ストアが利用できません");
      return;
    }
    final response = await _inAppPurchase.queryProductDetails(_storeProductIds.values.toSet());
    if (response.error != null) {
      print("課金アイテム取得失敗:${response.error}");
      return;
    }
    if (response.productDetails.isEmpty) {
      print("課金アイテムが見つかりません");
      return;
    }
    setState(() {
      _products = response.productDetails;
    });
    print("取得したアイテム: $_products");

    // 起動時にもサブスク状況チェック
    _checkSubscriptionStatus();
  }

  // フォアグラウンド or 起動時にサブスクチェック → 無ければ free
  Future<void> _checkSubscriptionStatus() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final skipRestore = sp.getBool('skipRestore') ?? false;
      print("skipRestore=$skipRestore");

      if (!skipRestore) {
        if (Platform.isIOS) {
          final storeKitAddition =
          _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
          // iOSの場合はレシート更新
          await storeKitAddition.refreshPurchaseVerificationData();
        }
        // restorePurchases()はエラーが起きやすいので try-catch で囲んでおく
        try {
          await _inAppPurchase.restorePurchases();
        } catch (e) {
          print("restorePurchasesでエラー:$e");
        }
      } else {
        print("手動リセット後なのでストア同期をスキップします");
      }
    } catch (e) {
      print("サブスク確認エラー:$e");
    }

    // 1秒後に何も無ければ free
    Future.delayed(const Duration(seconds:1), (){
      if (!_hasActivePlan) {
        ref.read(subscriptionStatusProvider.notifier).saveStatus("free");
        print("サブスクなし => free");
      }
    });
  }

  // purchaseStream のハンドリング
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    bool foundPlan = false;
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print("課金処理中:${purchaseDetails.productID}");
      }
      else if (purchaseDetails.status == PurchaseStatus.purchased
          || purchaseDetails.status == PurchaseStatus.restored) {

        final currentPlan = ref.read(subscriptionStatusProvider);
        if (currentPlan == SubscriptionStatusViewModel.cancellationPending) {
          print("現在のステータスが 'cancellation_pending' のため、purchased/restored を無視します。");
          continue;
        }

        // Androidで「本当に購読中か」チェックしたい場合
        if (Platform.isAndroid && purchaseDetails is GooglePlayPurchaseDetails) {
          final billingPurchase = purchaseDetails.billingClientPurchase;
          if (billingPurchase != null) {
            if (billingPurchase.purchaseState != 1 || billingPurchase.isAutoRenewing == false) {
              print("Android側でサブスクが解約・期限切れと判断: ${purchaseDetails.productID}");
              continue;
            }
          }
        }

        foundPlan = true;
        print("課金成功 or リストア:${purchaseDetails.productID}");
        _handlePurchaseSuccess(purchaseDetails);

      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print("課金エラー:${purchaseDetails.error}");
        UIUtils.showErrorDialog(
            context,
            "課金エラー:${purchaseDetails.error?.message??''}"
        );
      }

      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
    _hasActivePlan = foundPlan;
    // もし一つも見つからなければ free
    if (!foundPlan) {
      Future.delayed(const Duration(seconds:1),(){
        if (!_hasActivePlan) {
          ref.read(subscriptionStatusProvider.notifier).saveStatus("free");
        }
      });
    }
  }

  // 購入成功時
  Future<void> _handlePurchaseSuccess(PurchaseDetails purchaseDetails) async {
    final pid = purchaseDetails.productID;
    String planId = "free";
    // productId→planId 逆引き
    _storeProductIds.forEach((key,val){
      if (val==pid) {
        planId= key;
      }
    });

    await ref.read(subscriptionStatusProvider.notifier).saveStatus(planId);
    print("課金プラン:$planId に更新");

    // Firebaseに保存
    await _firebaseAuthAndStoreData(planId);
  }

  // Firebase Auth & Firestoreにプラン記録
  Future<void> _firebaseAuthAndStoreData(String planId) async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser==null) {
      await auth.signInAnonymously();
    }
    final user= auth.currentUser;
    if (user==null) {
      print("FirebaseAuthでUID取得できません");
      return;
    }
    final uid= user.uid;
    print("uid=$uid でログイン中(購入後)");

    final sp= await SharedPreferences.getInstance();
    await sp.setString('firebase_uid', uid);

    final docRef= FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('subscription')
        .doc('current');
    await docRef.set({
      'planId': planId,
      'updatedAt': FieldValue.serverTimestamp(),
    },SetOptions(merge:true));
    print("Firestoreに課金情報保存: planId=$planId");
  }

  // 課金フロー開始
  Future<void> _startPurchase(String planId) async {
    final productId= _storeProductIds[planId];
    if(productId==null){
      UIUtils.showErrorDialog(context,"課金アイテムが設定されていません($planId)");
      return;
    }
    final product= _products.firstWhere(
          (p)=> p.id==productId,
      orElse:()=> throw Exception("該当productなし:$productId"),
    );
    final purchaseParam= PurchaseParam(productDetails:product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // ボタンから呼ばれる => 課金開始
  Future<void> _subscribePlan(WidgetRef ref, String planId) async {
    try {
      await _startPurchase(planId);
    } catch (e) {
      UIUtils.showErrorDialog(context,"課金フローでエラー:$e");
    }
  }

  // 退会ボタン
  void _unsubscribePlan(WidgetRef ref, String planId) async {
    // 退会処理中にしておく
    await ref.read(subscriptionStatusProvider.notifier).saveStatus(
        SubscriptionStatusViewModel.cancellationPending
    );

    // ★ 修正：退会時にサインアウト & SharedPreferences上書き or 削除
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        print("[DEBUG] _unsubscribePlan => signOut from FirebaseAuth");
        await auth.signOut();
      }
      final sp = await SharedPreferences.getInstance();
      print("[DEBUG] _unsubscribePlan => clear subscription_plan");
      await sp.remove('subscription_plan');
      // skipRestore=true 等も設定したければ以下を有効化
      // await sp.setBool('skipRestore', true);
    } catch (e) {
      print("[ERROR] unsubscribe signOut or sp remove failed: $e");
    }

    _navigateToSubscriptionManagement();
  }

  // Apple/Google 課金管理ページ
  Future<void> _navigateToSubscriptionManagement() async {
    final url= (Platform.isIOS)
        ? "https://apps.apple.com/account/subscriptions"
        : "https://play.google.com/store/account/subscriptions";
    final uri= Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri,mode:LaunchMode.externalApplication);
    } else {
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan= ref.watch(subscriptionStatusProvider);

    // 課金プラン一覧
    // ★ isDev:true => (プレミアムプランを押せないように)
    final List<Map<String,dynamic>> plans= [
      {
        "id":"basic",
        "title":"ベーシックプラン",
        "price":100,
        "description":"""
・各金額カードをタップしてメモや編集が可能
・浪費スイッチでマイページに浪費額を表示
・貯金額の目標を設定可能
・設定固定費に「貯金」と入力すれば　貯金額をマイページで表示
・月次データをクラウドに24ヶ月保存
""",
        "isDev":false,
      },
      {
        "id":"premium",
        "title":"プレミアムプラン",
        "price":300,
        "description":"""
・収入/固定費/使った金額の種類をアイコン切替可
・支出額全体を種類別にグラフ化して分析
・カメラでレシート撮影して金額を自動入力
・コンシェルジュ機能で家計管理をサポート
""",
        "isDev":true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("課金プラン"),
        actions: [
          IconButton(
            onPressed: () async {
              final sp = await SharedPreferences.getInstance();
              await sp.setBool('skipRestore', false);
              print("skipRestore=false に設定して restorePurchases()再実行");
              _checkSubscriptionStatus();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for(final plan in plans)
              _buildPlanCard(
                context,ref,
                planId: plan["id"] as String,
                planTitle: plan["title"] as String,
                price: plan["price"] as int,
                description: plan["description"] as String,
                isDev: plan["isDev"] as bool,
              )
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
      }){
    final currentPlan= ref.watch(subscriptionStatusProvider);
    final bool isCurrent= (currentPlan== planId);
    final bool isCancelling=
    (currentPlan== SubscriptionStatusViewModel.cancellationPending);

    bool canUnsubscribe= isCurrent && !isCancelling && (planId!="free");

    String buttonLabel;
    bool disabled= false;
    if(isDev){
      buttonLabel= "選択できません";
      disabled= true;
    } else {
      if(isCurrent){
        buttonLabel= "退会する";
        if(!canUnsubscribe){
          disabled= true;
        }
      } else {
        buttonLabel= "選択する";
      }
    }

    final cardColor= isCurrent? Colors.lime[50]: null;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom:16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text(planTitle,
              style: const TextStyle(fontSize:20,fontWeight:FontWeight.bold),
            ),
            const SizedBox(height:8),

            if(isCurrent)
              const Text("現在加入中のプランです", style: TextStyle(color:Colors.red)),
            if(isDev)
              const Text("(現在開発中 近日リリース予定です)", style: TextStyle(color:Colors.red)),
            const SizedBox(height:8),

            Text(description, style: const TextStyle(fontSize:14)),
            const SizedBox(height:8),

            Text("¥${price.toString()} / 月",
              style: const TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:Colors.green),
            ),
            const SizedBox(height:8),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: disabled? null:
                (isCurrent
                    ? ()=>_unsubscribePlan(ref, planId)
                    : ()=>_subscribePlan(ref, planId)),
                child: Text(
                  buttonLabel,
                  style: TextStyle(color: Colors.cyan[800]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
