import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
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

  /// Firebaseの monthly_data から "貯金" の合計
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
        if (fc is Map<String,dynamic>) {
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
    final wasteTotal = expenses.where((e) => e.isWaste).fold<double>(0.0, (sum, e) => sum + e.amount);
    final nonWasteTotal = totalSpent - wasteTotal;

    final settings = ref.watch(settingsViewModelProvider);
    final isCalendarMode = settings.useCalendarForIncomeFixed;

    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPaidUser = (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    // 「毎月の貯金額」
    final savingsTotal = ref.watch(fixedCostViewModelProvider.notifier).savingsTotal;
    // 目標
    final savingsGoal = ref.watch(savingsGoalProvider);
    final goalController = TextEditingController();

    // メダル
    final medals = ref.watch(medalViewModelProvider);
    final last24 = medals.length > 24 ? medals.sublist(medals.length - 24) : medals;

    final dataMap = {
      "浪費": wasteTotal,
      "非浪費": nonWasteTotal,
    };

    return Scaffold(
      appBar: AppBar(
        // ★ leadingにアイコン配置: 課金プランのみ
        leading: isPaidUser
            ? IconButton(
          icon: const Icon(Icons.chevron_left),  // 「<」に近いアイコン
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const _HistoryPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // 左から右へ画面遷移するために Offset(-1.0, 0.0) -> Offset.zero にする
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  final tween = Tween(begin: begin, end: end);
                  final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
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
                  Text("使った金額合計: ${totalSpent.toStringAsFixed(0)}円"),
                  Text("浪費合計: ${wasteTotal.toStringAsFixed(0)}円"),
                  Text("浪費以外の金額: ${nonWasteTotal.toStringAsFixed(0)}円"),
                  const SizedBox(height: 20),
                  PieChart(
                    dataMap: dataMap,
                    chartType: ChartType.ring,
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

            // 貯金合計(過去+今月), 毎月の貯金額, 目標
            Card(
              margin: const EdgeInsets.only(bottom:16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical:16),
                child: Column(
                  children: [
                    Text("目標貯金額: ${savingsGoal.toStringAsFixed(0)} 円"),

                    // 過去+今月 => 貯金総額
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
                          padding: const EdgeInsets.only(top:8.0),
                          child: Text("貯金総額: ${totalSaving.toStringAsFixed(0)} 円"),
                        );
                      },
                    ),

                    const SizedBox(height:8),
                    // 毎月の貯金額
                    Text("毎月の貯金額: ${savingsTotal.toStringAsFixed(0)} 円"),

                    const SizedBox(height:16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: goalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "目標額を入力"),
                          ),
                        ),
                        const SizedBox(width:16),
                        ElevatedButton(
                          onPressed: () {
                            final newGoal = double.tryParse(goalController.text) ?? 0;
                            ref.read(savingsGoalProvider.notifier).setGoal(newGoal);
                          },
                          child: const Text("保存"),
                        ),
                        const SizedBox(width:16),
                      ],
                    ),
                    const SizedBox(height:8),
                    const Text("ホーム画面の固定費ページで種類に『貯金』と入力で管理"),
                  ],
                ),
              ),
            ),

            // 日付入力モード
            Card(
              margin: const EdgeInsets.only(bottom:16),
              child: ListTile(
                title: const Text("日付入力方法 (総収入/固定費)"),
                subtitle: Text(isCalendarMode ? "カレンダー" : "毎月◯日"),
                trailing: Switch(
                  value: isCalendarMode,
                  onChanged: (val) {
                    ref
                        .read(settingsViewModelProvider.notifier)
                        .setCalendarModeForIncomeFixed(val);
                  },
                ),
              ),
            ),

            // メダルグリッド
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

  // ---- 無料プラン
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
    switch(medal.type) {
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
        medalWidget = const Icon(Icons.sentiment_neutral, color: Colors.grey, size: 32);
        label = "未達成";
        break;
    }
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          medalWidget,
          const SizedBox(height:4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ★ 履歴ページ(読み取り専用)
class _HistoryPage extends StatelessWidget {
  const _HistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("過去データ（閲覧のみ）"),
      ),
      body: FutureBuilder<List<Map<String,dynamic>>>(
        future: _fetchAllMonthlyDocs(),
        builder: (ctx, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("エラー: ${snapshot.error}"));
          }
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("履歴がありません"));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i){
              final doc = docs[i];
              final monthId = doc['monthId'] as String? ?? 'unknown';
              return Card(
                child: ListTile(
                  title: Text("月: $monthId"),
                  subtitle: Text(
                      "固定費:${(doc['fixedCosts'] as List).length}件 "
                          "収入:${(doc['incomes'] as List).length}件 "
                          "支出:${(doc['expenses'] as List).length}件"
                  ),
                  onTap: (){
                    _showDetailDialog(context, doc);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String,dynamic>>> _fetchAllMonthlyDocs() async {
    final sp = await SharedPreferences.getInstance();
    final uid = sp.getString('firebase_uid') ?? '';
    if (uid.isEmpty) return [];

    final fs = FirebaseFirestore.instance;
    final snap = await fs
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .orderBy('timestamp', descending:true)
        .get();

    final list = <Map<String,dynamic>>[];
    for (final d in snap.docs){
      final data = d.data();
      data['monthId'] = d.id;
      list.add(data);
    }
    return list;
  }

  void _showDetailDialog(BuildContext context, Map<String,dynamic> docData){
    showDialog(
      context: context,
      builder: (_){
        return AlertDialog(
          title: const Text("詳細 (編集不可)"),
          content: SingleChildScrollView(
            child: Text(docData.toString()),
          ),
          actions:[
            TextButton(
              onPressed: ()=>Navigator.pop(context),
              child: const Text("閉じる"),
            )
          ],
        );
      },
    );
  }
}
