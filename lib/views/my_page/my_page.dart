import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  Future<double>? _futurePastSavingSum;

  @override
  void initState() {
    super.initState();
    final subStatus = ref.read(subscriptionStatusProvider);
    if (subStatus == 'basic' || subStatus == 'premium') {
      // 過去の貯金合計 (Firebase)
      _futurePastSavingSum = _fetchPastSavings();
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
    final expenses = ref.watch(expenseViewModelProvider);
    final totalSpent = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final wasteTotal = expenses
        .where((e) => e.isWaste)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final nonWasteTotal = totalSpent - wasteTotal;

    final settings = ref.watch(settingsViewModelProvider);
    final isCalendarMode = settings.useCalendarForIncomeFixed;

    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPaidUser =
        (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    // 毎月の貯金額と目標はそれぞれ ViewModel から取得
    final savingsTotal =
        ref.watch(fixedCostViewModelProvider.notifier).savingsTotal;
    final savingsGoal = ref.watch(savingsGoalProvider);
    final goalController = TextEditingController();

    // メダル
    final medals = ref.watch(medalViewModelProvider);
    final last24 =
        medals.length > 24 ? medals.sublist(medals.length - 24) : medals;

    // PieChart 用のデータマップ(ここでは支出と浪費の順番は元通り)
    final dataMap = {
      "浪費": wasteTotal,
      "支出": nonWasteTotal,
    };

    return Scaffold(
      appBar: AppBar(
        // 課金ユーザーのみ左側に戻るアイコン
        leading: isPaidUser
            ? IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const HistoryPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
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
        title: const Text("マイページ"),
      ),
      body: (subscriptionStatus == 'free')
          ? Center(child: _buildUpgradeMessage(context))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildSubscribedPlanCard(context, subscriptionStatus),
                  const SizedBox(height: 16),
                  // 使った金額 & 円グラフ
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
                          chartRadius:
                              MediaQuery.of(context).size.shortestSide * 0.3,
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValuesInPercentage: true,
                            decimalPlaces: 1,
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  // 貯金関連の表示
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
                                decoration:
                                    const InputDecoration(labelText: "目標額を入力"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                final newGoal =
                                    double.tryParse(goalController.text) ?? 0;
                                ref
                                    .read(savingsGoalProvider.notifier)
                                    .setGoal(newGoal);
                              },
                              child: const Text("保存"),
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
                              // 過去+今月 => 貯金総額
                              FutureBuilder<double>(
                                future: _futurePastSavingSum,
                                builder: (ctx, snap) {
                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
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
                                    child:
                                        _buildFixedRow("貯金の総額:", totalSaving),
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
                  // メダルグリッドはそのまま
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
    );
  }

  // ---------------------- 以下は既存の関数群 ---------------------------

  Widget _buildUpgradeMessage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showUpgradeDialog(context);
      },
      child: const Text(
        "無料プランでは\nこの機能は利用できません",
        style: TextStyle(
          fontSize: 24,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String getLocalizedPlanName(String planName) {
    switch (planName) {
      case "basic":
        return "ベーシックプラン";
      case "premium":
        return "プレミアムプラン";
      default:
        return "無料プラン";
    }
  }

  Widget _buildSubscribedPlanCard(BuildContext context, String planName) {
    final localizedPlanName = getLocalizedPlanName(planName);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$localizedPlanNameに加入中",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "現在のプランを変更または確認する場合は以下をタップしてください。",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SubscriptionPage()),
                  );
                },
                child: const Text("課金プランを見る"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("プランを選択してください"),
          content: const Text("この機能を利用するには課金プランへの加入が必要です。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionPage()),
                );
              },
              child: const Text("課金プランを確認する"),
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
        medalWidget = Image.asset("assets/images/金.png", width: 32, height: 32);
        label = "金";
        break;
      case MedalType.silver:
        medalWidget = Image.asset("assets/images/銀.png", width: 32, height: 32);
        label = "銀";
        break;
      case MedalType.bronze:
        medalWidget = Image.asset("assets/images/銅.png", width: 32, height: 32);
        label = "銅";
        break;
      default:
        medalWidget =
            const Icon(Icons.sentiment_neutral, color: Colors.grey, size: 32);
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

  // 修正した _buildFixedRow
  Widget _buildFixedRow(String label, double amount) {
    final formattedAmount = NumberFormat("#,##0").format(amount);
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 40),
      child: Row(
        children: [
          // ラベル部分：左揃え・固定幅
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // 金額部分：右揃え、Container で固定幅（動的な金額が更新されても変化する）
          SizedBox(
            width: 110, // 固定幅にする場合は、Container で十分
            child: Text(
              textAlign: TextAlign.end,
              formattedAmount,
              style: const TextStyle(
                fontSize: 14,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // 通貨記号部分：固定幅
          Container(
            width: 20,
            alignment: Alignment.centerLeft,
            child: const Text(
              "円",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
