import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/main.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/my_page/subscription_page.dart';


/// ConsumerStatefulWidget に変更し、createState() を正しくオーバーライド
class MySettingPage extends ConsumerStatefulWidget {
  // ★ 初回起動かどうかのフラグ
  final bool isFirstTime;

  const MySettingPage({
    Key? key,
    this.isFirstTime = false,
  }) : super(key: key);

  @override
  MySettingPageState createState() => MySettingPageState();
}

/// Stateクラスは ConsumerState<MySettingPage> を継承
class MySettingPageState extends ConsumerState<MySettingPage> {
  @override
  void initState() {
    super.initState();
    // 初回起動なら、画面描画後に利用規約ダイアログを自動表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isFirstTime) {
        _showTermsOfService(context, firstTime: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch(...) はここで使える
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    // 戻るボタンでロゴに戻す (往復させる) => WillPopScope
    return WillPopScope(
      onWillPop: () async {
        if (widget.isFirstTime) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OpeningScreen()),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("マイ設定ページ"),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ──────────────────────────────────────
              // 既存の文言や機能は削除・変更しない
              // ──────────────────────────────────────

              // マイページから移動してきた「課金プラン加入Card」
              _buildSubscribedPlanCard(context, subscriptionStatus),
              const SizedBox(height: 16),

              // 利用規約Card
              Card(
                child: ListTile(
                  title: const Text("利用規約"),
                  onTap: () {
                    // 通常時 => firstTime=false
                    _showTermsOfService(context, firstTime: false);
                  },
                ),
              ),
              // プライバシーポリシーCard
              Card(
                child: ListTile(
                  title: const Text("プライバシーポリシー"),
                  onTap: () {
                    _showPrivacyPolicy(context);
                  },
                ),
              ),
              const SizedBox(height: 32),

              // 設定ページから移動してきた「全データ消去」(Card)
              Card(
                child: ListTile(
                  title: const Text("全データ消去"),
                  subtitle: const Text("すべてのデータを消去して初期状態に戻します。"),
                  onTap: () {
                    int newDay = 1;
                    _confirmResetData(context, ref, newDay);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 以下、既存機能・文言をそのまま利用
  // ─────────────────────────────────────────────

  Widget _buildSubscribedPlanCard(BuildContext context, String planName) {
    String localizedPlanName;
    switch (planName) {
      case "basic":
        localizedPlanName = "ベーシックプラン";
        break;
      case "premium":
        localizedPlanName = "プレミアムプラン";
        break;
      default:
        localizedPlanName = "無料プラン";
        break;
    }
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
                child: Text(
                  "課金プランを見る",
                  style: TextStyle(color: Colors.cyan[800]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetData(BuildContext context, WidgetRef ref, int newDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("確認"),
          content: const Text(
            "全データを消去します。\nよろしいですか？",
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSecondConfirmation(context, ref, newDay);
              },
              child: Text("OK", style: TextStyle(color: Colors.cyan[800])),
            ),
          ],
        );
      },
    );
  }

  void _showSecondConfirmation(BuildContext context, WidgetRef ref, int newDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("最終確認"),
          content: const Text("本当に全データを消去してもよろしいですか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800])),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetData(ref);
                print("データがリセットされ、開始日が更新されました: $newDay");
              },
              child: Text("OK", style: TextStyle(color: Colors.cyan[800])),
            ),
          ],
        );
      },
    );
  }

  void _resetData(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // プロバイダの状態リセット
    ref.read(startDayProvider.notifier).state = 1;
    ref.read(customCategoryProvider.notifier).state = [];
    ref.read(typeProvider.notifier).state = [];
    ref.read(pageIndexProvider.notifier).state = 1;
    ref.read(incomeViewModelProvider.notifier).state = [];
    ref.read(fixedCostViewModelProvider.notifier).state = [];
    ref.read(expenseViewModelProvider.notifier).state = [];
    ref.read(budgetPeriodProvider.notifier).state = "";

    ref.read(settingsViewModelProvider.notifier).resetToDefaultSettings();
    // カレンダーモードに強制
    ref.read(settingsViewModelProvider.notifier).setCalendarModeForIncomeFixed(true);

    // 課金状態 => free
    ref.read(subscriptionStatusProvider.notifier).state = 'free';
    await prefs.setString('subscription_plan', 'free');

    // Expand系リセット
    ref.read(incomeExpandProvider.notifier).state = false;
    ref.read(fixedCostsExpandProvider.notifier).state = false;
    ref.read(expenseExpandProvider.notifier).state = false;
  }

  // 利用規約ダイアログ
  void _showTermsOfService(BuildContext context, {bool firstTime = false}) {
    showDialog(
      context: context,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text("利用規約"),
            content: const SingleChildScrollView(
              child: Text(
                """【利用規約】
この利用規約（以下、「本規約」）は、GappsOn（以下、「当社」）が提供する家計簿アプリ「予算deカケーボ」（以下、「本アプリ」）の利用条件を定めるものです。
本アプリをご利用になる方（以下、「ユーザー」）は、本規約に同意の上で本アプリを利用するものとします。

第1条（適用範囲）
1.本規約は、ユーザーが本アプリを利用するすべての場合に適用されます。
2.当社は、本規約をユーザーへの事前の通知なく改訂することがあります。

第2条（利用登録）
1.ユーザーは、本アプリを利用するにあたり、メールアドレスやパスワード等の登録情報を正確に提供する必要があります。
2.登録情報に虚偽があった場合、当社はアカウントを削除する権利を有します。

第3条（禁止事項）
1.ユーザーは、本アプリの利用に際して、以下の行為を行ってはなりません。
・法令や公序良俗に違反する行為
・当社または第三者の権利を侵害する行為
・不正アクセスや不正行為
・他人になりすます行為

第4条（免責事項）
1.当社は、本アプリの内容や機能について、正確性・有用性・完全性を保証するものではありません。
2.ユーザーが本アプリを利用することにより生じた損害について、当社は一切責任を負いません。

第5条（利用の制限・停止）
1.当社は、以下の場合にユーザーへの通知なく本アプリの提供を停止することができます。
2.システム保守やアップデート
3.不正行為が確認された場合
4.法令や規約違反があった場合

第6条（知的財産権）
1.本アプリに関する著作権・商標権等の知的財産権は、当社またはライセンサーに帰属します。
2.ユーザーは、当社の事前の同意なく、本アプリのコンテンツを複製、転載、改変等を行うことはできません。

第7条（準拠法・管轄裁判所）
1.本規約は日本法に準拠し、解釈されるものとします。
2.本規約に関する紛争は、東京地方裁判所を第一審の専属管轄裁判所とします。

第8条（お問い合わせ）
1.本規約に関するお問い合わせは、以下の連絡先までお願いいたします。

社名：GappsOn
メールアドレス：gappson55@gmail.com

""",
              ),
            ),
            actions: [
              // 「閉じる」
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // ダイアログ閉じる
                  if (firstTime) {
                    // オープニングロゴへ戻す => 2秒後に再度MySettingPage
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OpeningScreen()),
                    );
                  }
                },
                child: Text("閉じる", style: TextStyle(color: Colors.cyan[800])),
              ),
              // 「同意する」 (初回のみ)
              if (firstTime)
                TextButton(
                  onPressed: () async {
                    // 同意 => termsAccepted=true
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('termsAccepted', true);

                    Navigator.pop(context);

                    // メイン画面へ
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyApp(isAccepted: true),
                        ),
                      );
                    }
                  },
                  child: Text("同意する", style: TextStyle(color: Colors.cyan[800])),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("プライバシーポリシー"),
        content: const SingleChildScrollView(
          child: Text(
            """【プライバシーポリシー】
GappsOn（以下、「当社」）は、ユーザーのプライバシーを尊重し、個人情報を適切に保護するために、
以下のプライバシーポリシー（以下、「本ポリシー」）を定めます。

第1条（収集する情報）
当社は、本アプリの提供に必要な範囲で以下の情報を収集します。
1.ユーザー情報
・メールアドレス
・ユーザーID
2.家計データ
・収入・支出データ
・固定費・支出項目・メモ等
3.デバイス情報
・デバイスID、OSバージョン
・IPアドレス
4.クラッシュレポートおよびアナリティクスデータ

第2条（情報の利用目的）
当社は、収集した情報を以下の目的で利用します。
1.本アプリの運営・提供
2.ユーザーサポート・不具合対応
3.本アプリの改善および新機能の開発
4.法令に基づく対応

第3条（第三者への提供）
当社は、以下の場合を除き、第三者に個人情報を開示しません。
・ユーザーの同意がある場合
・法令に基づく開示請求があった場合
・不正行為を防止するために必要な場合

第4条（情報の管理）
当社は、個人情報の漏洩、滅失または毀損の防止のために、以下の対策を講じます。
1.アクセス制限の実施
2.通信の暗号化
3.システムの定期的なメンテナンス

第5条（ユーザーの権利）
1.ユーザーは、自身の個人情報について開示・訂正・削除を求めることができます。
2.ユーザーは、当社が収集した情報の利用停止を求めることができます。

第6条（プライバシーポリシーの変更）
当社は、必要に応じて本ポリシーを変更することがあります。
変更内容は、本アプリ内で通知します。

第7条（お問い合わせ）
プライバシーポリシーに関するお問い合わせは、以下の連絡先までお願いいたします。

社名：GappsOn
メールアドレス：gappson55@gmail.com

""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("閉じる", style: TextStyle(color: Colors.cyan[800])),
          ),
        ],
      ),
    );
  }
}
