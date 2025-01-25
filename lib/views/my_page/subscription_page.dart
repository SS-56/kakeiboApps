import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';

class SubscriptionPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(subscriptionStatusProvider); // 現在の課金状態

    final List<Map<String, dynamic>> plans = [
      {
        "title": "basic",
        "displayTitle": "ベーシックプラン",
        "description": isPremium == "basic"
            ? Text(
          "現在加入中のプランです。",
          style: TextStyle(color: Colors.red),
        )
            : Text(
          """
・収入を月・週・日で入力できるよう選択可能。
・各金額パネルをタップしたらメモを入力可能。
・収入、固定費、使った金額の種類入力方式を\n　アイコンに変更可能。
・各金額パネルで、ご自身が「浪費」と感じたら、\n　浪費アイコンをタップすると浪費額合計を表示。
・1ヶ月を1/3して予算を管理し、使いすぎの場合は\n　画面の色を変えてお知らせ。
・毎月のデータをクラウドに24ヶ月間保存して、\n　いつでも確認可能。
                """,
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.left,
        ),
        "price": "¥100",
        "isDisabled": isPremium == "premium",
        "onTapSubscribe": isPremium == "premium"
            ? null
            : () => _subscribe(ref, "basic"),
        "onTapUnsubscribe": isPremium == "basic"
            ? () => _navigateToSubscriptionManagement()
            : null,
      },
      {
        "title": "premium",
        "displayTitle": "プレミアムプラン",
        "description": isPremium == "premium"
            ? Text(
          "現在加入中のプランです。",
          style: TextStyle(color: Colors.red),
        )
            : Text(
          """
・浪費と支出の割合をグラフで確認可能。
・店ごとや買い物ごとに支出額と浪費額を比較可能。
・カメラでレシートから金額を自動入力。
・コンシェルジュ機能で家計管理をサポート。
                """,
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.left,
        ),
        "price": "¥300",
        "isDisabled": isPremium == "basic",
        "onTapSubscribe": isPremium == "basic"
            ? null
            : () => _subscribe(ref, "premium"),
        "onTapUnsubscribe": isPremium == "premium"
            ? () => _navigateToSubscriptionManagement()
            : null,
      }
    ];

    // プレミアムプランが優先される場合
    if (isPremium == "premium") {
      plans.sort((a, b) => a["title"] == "premium" ? -1 : 1);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("課金プラン"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var plan in plans)
              _buildPlanCard(
                context,
                ref,
                title: plan["title"] as String,
                displayTitle: plan["displayTitle"] as String,
                description: plan["description"] as Widget,
                isDisabled: plan["isDisabled"] as bool,
                price: plan["price"] as String,
                onTapSubscribe: plan["onTapSubscribe"] as VoidCallback?,
                onTapUnsubscribe: plan["onTapUnsubscribe"] as VoidCallback?,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context,
      WidgetRef ref, {
        required String title,
        required String displayTitle,
        required Widget description,
        required bool isDisabled,
        required String price,
        required VoidCallback? onTapSubscribe,
        required VoidCallback? onTapUnsubscribe,
      }) {
    final isPremium = ref.watch(subscriptionStatusProvider);

    return Card(
      color: isPremium == title ? Colors.lime[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            description,
            SizedBox(height: 8),
            Text(
              "$price/月",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isDisabled
                    ? null
                    : (isPremium == title ? onTapUnsubscribe : onTapSubscribe),
                child: Text(
                  isDisabled
                      ? "選択できません"
                      : (isPremium == title ? "退会する" : "選択する"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe(WidgetRef ref, String plan) async {
    try {
      await ref.read(subscriptionStatusProvider.notifier).saveStatus(plan);

      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text("$plan に加入しました")),
      );
    } catch (error) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text("エラーが発生しました: $error")),
      );
    }
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
