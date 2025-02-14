import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/utils/date_utils.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/home/expense_section.dart';
import 'package:yosan_de_kakeibo/views/my_page/subscription_page.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart'; // showMyDatePicker をimport


class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDay = ref.watch(startDayProvider);
    final customCategories = ref.watch(customCategoryProvider);
    final types = ref.watch(typeProvider);
    final isPremium = ref.watch(subscriptionStatusProvider);
    final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("設定"),
      ),
      body: ListTileTheme(
        contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0), // 統一された高さ調整
        dense: false, // 必要に応じてtrueにするとコンパクトな高さ
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text("家計簿の管理を開始する日にち"),
              subtitle: GestureDetector(
                onTap: () => _selectStartDay(context, ref),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            "現在: ${ref.watch(startDayProvider)}日",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.calendar_today, color: Colors.blue),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                      child: Text(
                        ref.watch(budgetPeriodProvider).isNotEmpty
                            ? ref.watch(budgetPeriodProvider) // メッセージがある場合は表示
                            : "", // 空の場合は何も表示しない
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            Divider(),
            // 通知設定
            ListTile(
              title: Text("通知設定"),
              subtitle: Text(
                ref.watch(notificationSettingProvider) ? "オン" : "オフ",
                style: TextStyle(fontSize: 14),
              ),
              trailing: Switch(
                value: ref.watch(notificationSettingProvider),
                onChanged: (value) {
                  ref.read(notificationSettingProvider.notifier).toggleNotification(value);
                  print("通知設定が変更されました: $value");
                },
              ),
            ),
            Divider(),

// データ同期設定
            ListTile(
              title: Text("データ同期 (プレミアム)"),
              subtitle: Text(
                ref.watch(dataBackupProvider)
                    ? "オン - データは同期されています"
                    : "オフ - データ同期を有効にしてください",
                style: TextStyle(fontSize: 14),
              ),
              trailing: Switch(
                value: ref.watch(dataBackupProvider),
                onChanged: (value) {
                  final isPremium = ref.watch(subscriptionStatusProvider) == 'basic';
                  if (isPremium) {
                    ref.read(dataBackupProvider.notifier).toggleBackup(value);
                    print("データ同期設定が変更されました: $value");
                  } else {
                    _showUpgradeDialog(context); // プレミアムへの誘導ダイアログ
                  }
                },
              ),
            ),
            Divider(),
            ListTile(
              title: Text(
                "種類のカテゴリーを増やす",
                style: TextStyle(
                  color: isPremium == 'basec' ? Colors.black : Colors.grey,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  customCategories.isEmpty
                      ? "カスタムカテゴリーはありません"
                      : "現在のカテゴリー: ${customCategories.join(', ')}",
                  style: TextStyle(
                    color: isPremium == 'basic' ? Colors.black : Colors.grey,
                  ),
                ),
              ),
              onTap: () {
                if (isPremium == 'basic') {
                  _addCategory(context, ref);
                } else {
                  _showUpgradeDialog(context);
                }
              },
            ),
            Divider(),
            ListTile(
              title: Text(
                "種類を追加",
                style: TextStyle(
                  color: isPremium == 'basic' ? Colors.black : Colors.grey,
                ),
              ),
              subtitle: types.isEmpty
                  ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "追加された種類はありません",
                  style: TextStyle(color: isPremium == 'basic' ? Colors.black : Colors.grey),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: types.map((type) {
                    return Row(
                      children: [
                        Icon(
                          type['icon'],
                          color: isPremium == 'basic' ? Colors.black : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          type['name'],
                          style: TextStyle(color: isPremium == 'basic' ? Colors.black : Colors.grey),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              onTap: () {
                if (isPremium == 'basic') {
                  _addType(context, ref);
                } else {
                  _showUpgradeDialog(context);
                }
              },
            ),
            Divider(),
            ListTile(
              title: Text("金額データの並び順"),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: ref.watch(sortOrderProvider),
                        onChanged: (value) {
                          ref.read(sortOrderProvider.notifier).updateSortOrder(value!);
                          ref.read(incomeViewModelProvider.notifier).sortItems(value);
                          ref.read(fixedCostViewModelProvider.notifier).sortItems(value);
                        },
                      ),
                      Text("下に追加"),
                    ],
                  ),
                  SizedBox(width: 16), // 隙間を空ける
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: ref.watch(sortOrderProvider),
                        onChanged: (value) {
                          ref.read(sortOrderProvider.notifier).updateSortOrder(value!);
                          ref.read(incomeViewModelProvider.notifier).sortItems(value);
                          ref.read(fixedCostViewModelProvider.notifier).sortItems(value);
                        },
                      ),
                      Text("上に追加"),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            ListTile(
              title: Text("全データ消去"),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text("すべてのデータを消去して初期状態に戻します。"),
              ),
              trailing: GestureDetector(
                onTap: () {
                  int newDay = 1; // 必要に応じて値を変更
                  _confirmResetData(context, ref, newDay); // アイコンタップ時に処理を実行
                },
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
  /// 通常のshowDatePickerをラップした関数
  Future<DateTime?> showMyDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    return picked; // null ならキャンセル。DateTimeなら選択日付。
  }

  void _confirmResetData(BuildContext context, WidgetRef ref, int newDay) {
    // 最初の確認を表示
    _showFirstConfirmation(context, ref, newDay);
  }

  void _selectStartDay(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    // 現在の開始日
    final selectedDay = ref.read(startDayProvider);

    // 既定のinitialDate (「現在の開始日」を使う)
    final initialDate = DateTime(now.year, now.month, selectedDay);

    // カレンダー選択の範囲を簡単に当月に限定する例
    final firstDate = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0).day; // 月末日
    final lastDate = DateTime(now.year, now.month, lastDay);

    final pickedDate = await showMyDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      // 新しい日が選ばれた
      if (pickedDate.day != selectedDay) {
        // 開始日が変わるなら確認ダイアログ
        _updateStartDay(ref, pickedDate.day);
      } else {
        print("日付に変更はありません");
      }
    } else {
      print("ユーザーがキャンセルしました");
    }
  }

  /// 開始日を変更する確認ダイアログ例
  void _confirmStartDateChange(
      BuildContext context,
      WidgetRef ref,
      DateTime newDate,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("開始日を変更してもいいですか？"),
        content: Text("${newDate.month}月${newDate.day}日に変更します。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 開始日を更新
              ref.read(startDayProvider.notifier).state = newDate.day;
              print("開始日を${newDate.day}日に変更しました");
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _updateStartDay(WidgetRef ref, int newDay) {
    ref.read(startDayProvider.notifier).setStartDay(newDay); // 状態を更新
    print("開始日が更新されました: $newDay 日");

    // 管理期間メッセージの更新
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, newDay);
    final endDate = calculateEndDate(startDate);

    // データのフィルタリングと管理期間の更新
    ref.read(expenseViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    ref.read(fixedCostViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    ref.read(incomeViewModelProvider.notifier).filterByDateRange(startDate, endDate);

    String budgetPeriodMessage =
        "${startDate.month}月${startDate.day}日から${endDate.month}月${endDate.day}日までを管理します";
    ref.read(budgetPeriodProvider.notifier).state = budgetPeriodMessage;

    print("管理期間メッセージ: $budgetPeriodMessage");
  }

  void _showFirstConfirmation(BuildContext context, WidgetRef ref, int newDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("確認"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "全データを消去します。\nよろしいですか？", // \nで改行を挿入
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),// 必要に応じて中央揃え),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSecondConfirmation(context, ref, newDay); // 次の確認ステップへ
              },
              child: Text("OK"),
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
          title: Text("最終確認"),
          content: Text("本当に全データを消去してもよろしいですか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ダイアログを閉じる
                _resetData(ref); // データを消去
                _updateStartDay(ref, newDay); // 日付を更新
                print("データがリセットされ、開始日が更新されました: $newDay");
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _resetData(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();

    // SharedPreferencesのすべてのデータを削除
    await prefs.clear();

    // 状態のリセット
    ref.read(startDayProvider.notifier).state = 1;
    ref.read(customCategoryProvider.notifier).state = [];
    ref.read(typeProvider.notifier).state = [];
    ref.read(pageIndexProvider.notifier).state = 1;
    ref.read(incomeViewModelProvider.notifier).state = [];
    ref.read(fixedCostViewModelProvider.notifier).state = [];
    ref.read(expenseViewModelProvider.notifier).state = [];
    ref.read(budgetPeriodProvider.notifier).state = "";

    // 課金状態を初期化 ('free'にリセット)
    ref.read(subscriptionStatusProvider.notifier).state = 'free';
    await prefs.setString('subscription_plan', 'free'); // 永続データもリセット

    // セクションの展開状態をリセット
    ref.read(incomeExpandProvider.notifier).state = false;
    ref.read(fixedCostsExpandProvider.notifier).state = false;
    ref.read(expensesExpandProvider.notifier).state = false;
  }

  void _addCategory(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(subscriptionStatusProvider); // 課金状態を取得
    print("Current isPremium value: $isPremium");

    if (isPremium != 'basic') {
      // 無料ユーザーは課金プラン加入ページに遷移
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubscriptionPage()),
      );
      return;
    }

    // ベーシックユーザーは現在のロジックを実行
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("カテゴリーを追加"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "カテゴリー名を入力"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                final newCategory = controller.text.trim();
                if (newCategory.isNotEmpty) {
                  ref.read(customCategoryProvider.notifier).state =
                  [...ref.read(customCategoryProvider), newCategory];
                }
                Navigator.pop(context);
              },
              child: Text("追加"),
            ),
          ],
        );
      },
    );
  }

  void _addType(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(subscriptionStatusProvider); // 課金状態を取得
    print("Current isPremium value: $isPremium");

    if (isPremium != 'basic') {
      // 無料ユーザーは課金プラン加入ページに遷移
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubscriptionPage()),
      );
      return;
    }

    // ベーシックユーザーは現在のロジックを実行
    final controller = TextEditingController();
    IconData? selectedIcon;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("種類を追加"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(hintText: "種類名を入力"),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  _iconChoice(Icons.local_dining, "食材", selectedIcon, (icon) {
                    selectedIcon = icon;
                  }),
                  _iconChoice(Icons.checkroom, "服", selectedIcon, (icon) {
                    selectedIcon = icon;
                  }),
                  _iconChoice(Icons.local_drink, "ボトル", selectedIcon, (icon) {
                    selectedIcon = icon;
                  }),
                  _iconChoice(Icons.receipt, "請求書", selectedIcon, (icon) {
                    selectedIcon = icon;
                  }),
                  _iconChoice(Icons.home, "家", selectedIcon, (icon) {
                    selectedIcon = icon;
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                final newType = controller.text.trim();
                if (newType.isNotEmpty && selectedIcon != null) {
                  ref.read(typeProvider.notifier).addType({
                    'name': newType,
                    'icon': selectedIcon,
                  });
                }
                Navigator.pop(context);
              },
              child: Text("追加"),
            ),
          ],
        );
      },
    );
  }

  Widget _iconChoice(IconData icon, String label, IconData? selectedIcon, ValueChanged<IconData> onSelected) {
    return GestureDetector(
      onTap: () => onSelected(icon),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: selectedIcon == icon ? Colors.blue : Colors.grey,
            size: 40,
          ),
          Text(label),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("プレミアムプランにアップグレード"),
          content: Text("この機能を利用するにはプレミアムプランへの加入が必要です。"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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

