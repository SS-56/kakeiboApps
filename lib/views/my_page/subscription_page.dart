import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlan = ref.watch(subscriptionStatusProvider); // e.g. "free"/"basic"/"premium"

    // プランリスト: basic / premium
    final List<Map<String, dynamic>> plans = [
      {
        "id": "basic",
        "title": "ベーシックプラン",
        "price": 100,
        "description": """
・各金額カードをタップしてメモや編集が可能
・浪費スイッチでマイページに浪費額を表示
・貯金額の目標を設定可能
・設定固定費に「貯金」と入力すれば\n　貯金額を残額から差引き
・月次データをクラウドに24ヶ月保存
        """,
        "isDev": false, // 開発中かどうか
      },
      {
        "id": "premium",
        "title": "プレミアムプラン",
        "price": 300,
        "description": """
・収入/固定費/使った金額の種類をアイコン切替可
・支出額全体を種類別にグラフ化して分析
・カメラでレシート撮影して金額を自動入力
・コンシェルジュ機能で家計管理をサポート
        """,
        "isDev": true,  // プレミアムはまだ開発中
      }
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("課金プラン")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final plan in plans) _buildPlanCard(context, ref,
              planId:       plan["id"]     as String,
              planTitle:    plan["title"]  as String,
              price:        plan["price"]  as int,
              description:  plan["description"] as String,
              isDev:        plan["isDev"]  as bool,
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
        required bool isDev, // "開発中"フラグ
      }) {
    final currentPlan = ref.watch(subscriptionStatusProvider);
    final bool isCurrent = (currentPlan == planId);

    // カード色: 現在加入中のプランは背景色を変える
    final cardColor = isCurrent ? Colors.lime[50] : null;

    // ボタンの文言 / 無効化
    String buttonLabel;
    bool disabled = false;
    if (isDev) {
      // 開発中 → 「選択できません」
      buttonLabel = "選択できません";
      disabled = true;
    } else {
      // 開発中でない → basicプラン
      if (isCurrent) {
        // 現在加入中 => 「退会する」
        buttonLabel = "退会する";
      } else {
        // 未加入 => 「選択する」
        buttonLabel = "選択する";
      }
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              planTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 「現在加入中のプランです」(赤)  or  空
            if (isCurrent)
              const Text(
                "現在加入中のプランです",
                style: TextStyle(color: Colors.red),
              ),
            // 「(開発中)」(赤)  if isDev
            if (isDev)
              const Text(
                "(現在開発中 近日リリース予定です)",
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 8),

            // 既存の案内文(通常表示)
            Text(
              description,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 8),

            // 価格
            Text(
              "¥${price.toString()} / 月",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),

            // ボタン
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: disabled
                    ? null
                    : (isCurrent
                    ? () => _unsubscribePlan(ref, planId)
                    : () => _subscribePlan(ref, planId)),
                child: Text(buttonLabel, style: TextStyle(color: Colors.cyan[800]),),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _subscribePlan(WidgetRef ref, String planId) async {
    try {
      await ref.read(subscriptionStatusProvider.notifier).saveStatus(planId);
    } catch (e) {
      UIUtils.showErrorDialog(ref.context, "課金プラン選択中にエラーが発生: $e");
    }
  }

  void _unsubscribePlan(WidgetRef ref, String planId) {
    // 「退会する」 => ストアのサブスク管理ページへ誘導
    _navigateToSubscriptionManagement();
  }

  Future<void> _navigateToSubscriptionManagement() async {
    final url = Platform.isIOS
        ? "https://apps.apple.com/account/subscriptions"
        : "https://play.google.com/store/account/subscriptions";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $url";
    }
  }
}
