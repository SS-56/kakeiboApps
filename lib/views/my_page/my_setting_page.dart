import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/my_page/subscription_page.dart';

class MySettingPage extends ConsumerWidget {
  const MySettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("マイ設定ページ"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // マイページから移動してきた「課金プラン加入Card」
            _buildSubscribedPlanCard(context, subscriptionStatus),
            const SizedBox(height: 16),

            // 利用規約Card
            Card(
              child: ListTile(
                title: const Text("利用規約"),
                onTap: () {
                  _showTermsOfService(context);
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
    );
  }

  /// 課金プランカード
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
                child: Text("課金プランを見る", style: TextStyle(color: Colors.cyan[800]),),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 全データ消去の確認ダイアログ
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
              child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800]),),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSecondConfirmation(context, ref, newDay);
              },
              child: Text("OK", style: TextStyle(color: Colors.cyan[800]),),
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
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetData(ref);
                // ここで開始日を newDay=1 に更新
                // 必要に応じて startDayProvider更新の処理を加えても良い
                print("データがリセットされ、開始日が更新されました: $newDay");
              },
              child: const Text("OK"),
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

  /// 利用規約ダイアログ
  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("利用規約"),
        content: const SingleChildScrollView(
          child: Text(
            """【利用規約】
本アプリのご利用にあたっては、以下の条件に同意いただく必要があります。

1. ユーザーは、本アプリを個人の家計管理目的でのみ利用できます。
2. 本アプリの内容は予告なく変更または終了する場合があります。
3. ユーザーが本アプリを利用することで得られる成果や損害について、開発者は一切の責任を負いません。

...（以下、必要に応じて追記）...
""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("閉じる", style: TextStyle(color: Colors.cyan[800]),),
          ),
        ],
      ),
    );
  }

  /// プライバシーポリシーダイアログ
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("プライバシーポリシー"),
        content: const SingleChildScrollView(
          child: Text(
            """【プライバシーポリシー】
1. 本アプリはユーザーの入力した家計データを個人情報として取り扱います。
2. 本アプリが取得するユーザーデータは、ユーザー自身の管理を目的とする以外の用途では使用しません。
3. ユーザーの明示的な同意なく、第三者に個人情報を提供することはありません。

...（以下、必要に応じて追記）...
""",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("閉じる", style: TextStyle(color: Colors.cyan[800]),),
          ),
        ],
      ),
    );
  }
}
