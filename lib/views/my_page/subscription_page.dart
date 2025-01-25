import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yosan_de_kakeibo/view_models/user_status_view_model.dart';

class SubscriptionPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(userStatusProvider); // 課金状態を取得

    // プランリストを作成
    final List<Map<String, dynamic>> plans = [
      {
        "title": "basic",
        "displayTitle": "ベーシックプラン",
        "description": isPremium == "basic"
            ? Text(
          "現在加入中のプランです。",
          style: TextStyle(color: Colors.red), // 赤文字
        )
            : Text(
          "ベーシックプランで利用可能な機能",
          style: TextStyle(color: Colors.black),
        ),
        "price": "¥100",
        "isDisabled": isPremium == "premium", // プレミアム加入中なら非活性
        "onTapSubscribe": isPremium == "premium" ? null : () => _subscribe(ref, "basic"),
        "onTapUnsubscribe": isPremium == "basic" ? () => _navigateToSubscriptionManagement() : null,
      },
      {
        "title": "premium",
        "displayTitle": "プレミアムプラン",
        "description": isPremium == "premium"
            ? Text(
          "現在加入中のプランです。",
          style: TextStyle(color: Colors.red), // 赤文字
        )
            : Text(
          "プレミアムプランで利用可能な機能",
          style: TextStyle(color: Colors.black),
        ),
        "price": "¥300",
        "isDisabled": isPremium == "basic", // ベーシック加入中なら非活性
        "onTapSubscribe": isPremium == "basic" ? null : () => _subscribe(ref, "premium"),
        "onTapUnsubscribe": isPremium == "premium" ? () => _navigateToSubscriptionManagement() : null,
      }
    ];

    // プレミアムプランに加入している場合のみ順序を変更
    if (isPremium == "premium") {
      plans.sort((a, b) => a["title"] == "premium" ? -1 : 1);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("課金プラン"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 動的にプランを表示
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
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context,
      WidgetRef ref, {
        required String title, // 内部状態に使用されるタイトル
        required String displayTitle, // 表示用タイトル
        required Widget description,
        required bool isDisabled, // 無効化状態
        required String price,
        required VoidCallback? onTapSubscribe,
        required VoidCallback? onTapUnsubscribe,
      }) {
    final isPremium = ref.watch(userStatusProvider);

    return Card(
      color: isPremium == title ? Colors.lime[50] : null, // 現在加入中なら色を変更
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
            if (title == "basic") ...[
              Text(
                """
・収入を月・週・日で入力できるよう選択可能。
・各金額パネルをタップしたらメモを入力可能。
・収入、固定費、使った金額の種類入力方式を\n　アイコンに変更可能。
・各金額パネルで、ご自身が「浪費」と感じたら、\n　浪費アイコンをタップすると浪費額合計を表示。
・1ヶ月を1/3して予算を管理し、使いすぎの場合は\n　画面の色を変えてお知らせ。
・毎月のデータをクラウドに24ヶ月間保存して、\n　いつでも確認可能。
                """,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.left, // 左揃え
              ),
            ] else if (title == "premium") ...[
              Text(
                """
・浪費と支出の割合をグラフで確認可能。
・店ごとや買い物ごとに支出額と浪費額を比較可能。
・カメラでレシートから金額を自動入力。
・コンシェルジュ機能で家計管理をサポート。
                """,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.left, // 左揃え
              ),
            ],
            Text(
              "$price/月",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (isPremium == title) ...[
              SizedBox(height: 8),
              Text(
                "※課金プランはいつでも退会可能ですが、\n プランの期間中は機能が利用可能です。",
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
            ],
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isDisabled ? null : (isPremium == title ? onTapUnsubscribe : onTapSubscribe),
                child: Text(
                  isDisabled ? "選択できません" : (isPremium == title ? "退会手続きを行う" : "選択する"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe(WidgetRef ref, String plan) async {
    // 課金状態を更新し、永続化
    print("選択されたプラン: $plan");
    await ref.read(userStatusProvider.notifier).saveStatus(plan);

    // プラン選択後のメッセージ表示
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(content: Text("$plan に加入しました")),
    );
  }

  Future<void> _navigateToSubscriptionManagement() async {
    String url;
    if (Platform.isIOS) {
      url = "https://apps.apple.com/account/subscriptions";
    } else if (Platform.isAndroid) {
      url = "https://play.google.com/store/account/subscriptions";
    } else {
      throw UnsupportedError("Unsupported platform");
    }

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch $url";
    }
  }
}
