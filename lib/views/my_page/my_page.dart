import 'dart:async';
import 'dart:ui'; // FontFeatureを使うのに必要
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/my_page/history_page.dart';
import 'package:yosan_de_kakeibo/views/my_page/subscription_page.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // 追加
import 'dart:async'; // 追加


// すでに用意済みのマイ設定ページを import
import 'package:yosan_de_kakeibo/views/my_page/my_setting_page.dart';

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  Future<double>? _futurePastSavingSum;
  late StreamSubscription<List<PurchaseDetails>> _subscription; // 追加

  @override
  void initState() {
    super.initState();
    // まず最新の購読状態を同期する
    ref.read(subscriptionStatusProvider.notifier).syncWithFirebase();

    final subStatus = ref.read(subscriptionStatusProvider);
    if (subStatus == 'basic' || subStatus == 'premium') {
      _futurePastSavingSum = _fetchPastSavings();
    }
    final Stream<List<PurchaseDetails>> purchaseStream = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseStream.listen((purchases) {
      _handlePurchases(purchases);
    });
  }

  @override
  void dispose() { // 追加
    _subscription.cancel(); // 追加
    super.dispose(); // 追加
  }

  void _handlePurchases(List<PurchaseDetails> purchases) async {
    if (purchases.isNotEmpty) {
      final purchase = purchases.first;
      if (purchase.status == PurchaseStatus.purchased) {
        if (purchase.productID == 'com.gappson56.yosandekakeibo.basicPlan') {
          ref.read(subscriptionStatusProvider.notifier).setSubscriptionStatus('basic');
          // 課金成功時の処理（例：Firebaseに課金情報を保存、UIを更新など）
        }
      } else if (purchase.status == PurchaseStatus.error) {
        // 課金エラー時の処理（例：エラーメッセージを表示）
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('課金エラー: ${purchase.error!.message}')));
      }
    }
  }

  /// Firebaseの monthly_data から "貯金" の合計を取得する
  Future<double> _fetchPastSavings() async {
    final sp = await SharedPreferences.getInstance();
    final uid = sp.getString('firebase_uid') ?? '';
    if (uid.isEmpty) return 0.0;

    final fs = FirebaseFirestore.instance;
    final snap = await fs
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .orderBy('timestamp', descending: false)
        .get();

    double total = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final fixedList = data['fixedCosts'] as List<dynamic>?;
      if (fixedList == null) continue;
      for (final fc in fixedList) {
        if (fc is Map<String, dynamic>) {
          if (fc['title'] == '貯金') {
            final amt = (fc['amount'] as num?)?.toDouble() ?? 0;
            total += amt;
          }
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPaidUser = (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    final expenses = ref.watch(expenseViewModelProvider);
    final totalSpent = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final wasteTotal = expenses.where((e) => e.isWaste).fold<double>(0.0, (sum, e) => sum + e.amount);
    final nonWasteTotal = totalSpent - wasteTotal;

    // 毎月の貯金額と目標
    final savingsTotal = ref.watch(fixedCostViewModelProvider.notifier).savingsTotal;
    final savingsGoal = ref.watch(savingsGoalProvider);
    final goalController = TextEditingController();

    // メダル一覧を取得
    final medals = ref.watch(medalViewModelProvider);
    // 直近24件だけ表示
    final last24 = (medals.length > 24) ? medals.sublist(medals.length - 24) : medals;

    // 円グラフ用
    final dataMap = {
      "浪費": wasteTotal,
      "支出": nonWasteTotal,
    };

    final _colorList = [
      Colors.red,
      Colors.cyan,
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        leading: isPaidUser
            ? IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            // 過去の実績画面(HistoryPage)へ
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const HistoryPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  final tween = Tween(begin: begin, end: end);
                  final curvedAnimation = CurvedAnimation(
                      parent: animation, curve: Curves.easeInOut);
                  return SlideTransition(
                    position: tween.animate(curvedAnimation),
                    child: child,
                  );
                },
              ),
            );
          },
        )
            : null,
        title: Text("マイページ", style: TextStyle(color: Colors.cyan[800]),),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.cyan[800]),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MySettingPage()),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: (subscriptionStatus == 'free')
            ? Center(child: _buildUpgradeMessage(context))
            : SingleChildScrollView(
          child: Column(
            children: [
              // 現在の課金プランを表示するカード
              _buildPlanStatusCard(subscriptionStatus),
              const SizedBox(height: 16),

              // 使った金額 & 円グラフ Card
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40.0),
                        child: Column(
                          children: [
                            _buildFixedRow("支出合計:", totalSpent),
                            _buildFixedRow("浪費合計:", wasteTotal),
                            _buildFixedRow("差引金額:", nonWasteTotal),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PieChart(
                      dataMap: dataMap,
                      chartType: ChartType.ring,
                      colorList: _colorList,
                      chartRadius: MediaQuery.of(context).size.shortestSide * 0.3,
                      chartValuesOptions: const ChartValuesOptions(
                        showChartValuesInPercentage: true,
                        decimalPlaces: 1,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // 貯金関連
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    const Text("ホーム画面の固定費ページで種類に\n『貯金』と入力して管理"),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: goalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.cyan),
                              ),
                              labelText: "目標額を入力",
                              floatingLabelStyle: TextStyle(color: Colors.cyan[800]),
                            ),
                            cursorColor: Colors.cyan[800],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            final newGoal = double.tryParse(goalController.text) ?? 0;
                            ref.read(savingsGoalProvider.notifier).setGoal(newGoal);
                          },
                          child: Text("保存", style: TextStyle(color: Colors.cyan[800])),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 40.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildFixedRow("目標貯金額:", savingsGoal),
                          FutureBuilder<double>(
                            future: _futurePastSavingSum,
                            builder: (ctx, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snap.hasError) {
                                return Text("貯金総額の取得失敗: ${snap.error}");
                              }
                              final pastSaving = snap.data ?? 0.0;
                              final totalSaving = pastSaving + savingsTotal;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: _buildFixedRow("貯金の総額:", totalSaving),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildFixedRow("当月貯金額:", savingsTotal),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // メダル表示: Grid
              Card(
                margin: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 400,
                  child: GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    children: last24.map((m) => buildMedalCell(m)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanStatusCard(String subscriptionStatus) {
    final planName = getLocalizedPlanName(subscriptionStatus);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                "$planNameに加入中",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getLocalizedPlanName(String planName) {
    switch (planName) {
      case "basic":
        return "ベーシックプラン";
      case "premium":
        return "プレミアムプラン";
      case "cancellation_pending":
        return "退会処理中";
      default:
        return "無料プラン";
    }
  }

  Widget _buildUpgradeMessage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showUpgradeDialog(context);
      },
      child: const Text(
        "無料プランでは\nこの機能は利用できません",
        style: TextStyle(fontSize: 24, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("プレミアムプランにアップグレード"),
          content: const Text("この機能を利用するには課金プランへの加入が必要です。"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionPage()),
                );
              },
              child: Text("課金プランを確認する", style: TextStyle(color: Colors.cyan[800])),
            ),
          ],
        );
      },
    );
  }

  Widget buildMedalCell(Medal medal) {
    Widget medalWidget;
    String label;
    switch (medal.type) {
      case MedalType.gold:
        medalWidget = const Icon(
          Icons.workspace_premium,
          color: Colors.amber,
          size: 48,
        );
        // Icon に直接キーを設定できない場合、KeyedSubtree でラップする
        medalWidget = KeyedSubtree(key: const Key('goldMedalIcon'), child: medalWidget);
        label = "金";
        break;
      case MedalType.silver:
        medalWidget = const Icon(
          Icons.workspace_premium,
          color: Colors.grey,
          size: 48,
        );
        medalWidget = KeyedSubtree(key: const Key('silverMedalIcon'), child: medalWidget);
        label = "銀";
        break;
      case MedalType.bronze:
        medalWidget = const Icon(
          Icons.workspace_premium,
          color: Colors.brown,
          size: 48,
        );
        medalWidget = KeyedSubtree(key: const Key('bronzeMedalIcon'), child: medalWidget);
        label = "銅";
        break;
      default:
        medalWidget = const Icon(
          Icons.sentiment_neutral,
          color: Colors.grey,
          size: 48,
        );
        medalWidget = KeyedSubtree(key: const Key('noneMedalIcon'), child: medalWidget);
        label = "未達成";
        break;
    }
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          medalWidget,
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFixedRow(String label, double amount) {
    final formattedAmount = NumberFormat("#,##0").format(amount);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(left: 40.0, right: 40),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, textAlign: TextAlign.left, style: const TextStyle(fontSize: 14)),
            ),
            SizedBox(
              width: 110,
              child: Text(
                formattedAmount,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 14, fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
            Container(
              width: 20,
              alignment: Alignment.centerLeft,
              child: const Text("円", style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
