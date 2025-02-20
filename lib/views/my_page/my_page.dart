import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/my_page/subscription_page.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final radius = size.shortestSide * 0.3; // 最短辺の30%
    final expenses = ref.watch(expenseViewModelProvider);
    final totalSpent = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final wasteTotal = expenses
        .where((e) => e.isWaste)
        .fold<double>(0.0, (sum, e) => sum + e.amount);
    final nonWasteTotal = totalSpent - wasteTotal;
    final settings = ref.watch(settingsViewModelProvider);
    final isCalendarMode = settings.useCalendarForIncomeFixed;
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    // 円グラフ用データ
    final dataMap = {
      "浪費": wasteTotal,
      "非浪費": nonWasteTotal,
    };


    return Scaffold(
      appBar: AppBar(title: Text("マイページ")),
      body: subscriptionStatus == 'free'
      // ★ 無料プランなら画面全体をCenterで固定
          ? Center(
        child: _buildUpgradeMessage(context),
      )

      // ★ 課金プランなら従来のSingleChildScrollView
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildSubscribedPlanCard(context, subscriptionStatus),

            // 浪費合計・円グラフなど
            Text("使った金額合計: ${totalSpent.toStringAsFixed(0)}円"),
            Text("浪費合計: ${wasteTotal.toStringAsFixed(0)}円"),
            Text("浪費以外の金額: ${nonWasteTotal.toStringAsFixed(0)}円"),
            SizedBox(height: 20),
            // 円グラフ
            PieChart(
              dataMap: dataMap,
              chartType: ChartType.ring,
              chartRadius: radius,
              chartValuesOptions: ChartValuesOptions(
                showChartValuesInPercentage: true,
                decimalPlaces: 1,
              ),
            ),

            // 日付入力方法
            ListTile(
              title: Text("日付入力方法 (総収入/固定費)"),
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
          ],
        ),
      ),
    );
  }


  // 無料プランの場合に表示するウィジェット
  Widget _buildUpgradeMessage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showUpgradeDialog(context); // 課金促進のダイアログを表示
      },
      child: Text(
        "無料プランでは\nこの機能は利用できません",
        style: TextStyle(
          fontSize: 24,
          color: Colors.grey, // 無料ユーザーは灰色で非アクティブに見せる
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // プラン名を日本語に変換する関数
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

  // 課金プランに加入済みの場合に表示するウィジェット
  Widget _buildSubscribedPlanCard(BuildContext context, String planName) {
    final localizedPlanName = getLocalizedPlanName(planName); // 日本語プラン名を取得
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$localizedPlanNameに加入中",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "現在のプランを変更または確認する場合は以下をタップしてください。",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubscriptionPage(),
                    ),
                  );
                },
                child: Text("課金プランを見る"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 無料ユーザーへの課金促進メッセージ
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("プランを選択してください"),
          content: Text("この機能を利用するには課金プランへの加入が必要です。"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ダイアログを閉じる
              },
              child: Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ダイアログを閉じる
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubscriptionPage()),
                ); // SubscriptionPageへの遷移を追加
              },
              child: Text("課金プランを確認する"),
            ),
          ],
        );
      },
    );
  }
}
