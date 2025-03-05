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
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/home/expense_section.dart';
import 'package:yosan_de_kakeibo/views/my_page/subscription_page.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart'; // showMyDatePicker をimport

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDay = ref.watch(startDayProvider);
    // -------------- 削除した: final customCategories = ref.watch(customCategoryProvider);
    final types = ref.watch(typeProvider);

    // 課金状態を取得
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    // 「ベーシック or プレミアム」
    final isPaidUser = (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    // 日付入力方法
    final isCalendarMode = ref.watch(settingsViewModelProvider).useCalendarForIncomeFixed;
    // スイッチがON => 「毎月◯日」モード
    final isEveryMonth = !isCalendarMode;

    // 水道代2ヶ月ごとのbool
    final isBimonthly = ref.watch(settingsViewModelProvider).isWaterBillBimonthly;

    final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("設定"),
      ),
      body: ListTileTheme(
        contentPadding: const EdgeInsets.symmetric(vertical:4.0, horizontal:16.0),
        dense: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --------------------------------------------------
            // 家計簿開始日
            ListTile(
              title: const Text("家計簿の管理を開始する日にち"),
              subtitle: GestureDetector(
                onTap: () => _selectStartDay(context, ref),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left:12.0),
                          child: Text(
                            "現在: $startDay日",
                            style: const TextStyle(fontSize:18, fontWeight:FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width:16),
                        const Icon(Icons.calendar_today, color: Colors.blue),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left:12.0, top:8.0),
                      child: Text(
                        ref.watch(budgetPeriodProvider).isNotEmpty
                            ? ref.watch(budgetPeriodProvider)
                            : "",
                        style: const TextStyle(fontSize:14, fontWeight:FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height:8),
            const Divider(),

            // --------------------------------------------------
            // 日付入力方法(総収入/固定費)
            ListTile(
              onTap: () {
                // ※元の挙動を維持 => 無料ユーザー => _showUpgradeDialog
                if (!isPaidUser) {
                  _showUpgradeDialog(context);
                  return;
                }
                // 課金ユーザ => 切り替え
                ref.read(settingsViewModelProvider.notifier)
                    .setCalendarModeForIncomeFixed(isEveryMonth);
              },
              title: Text(
                "日付入力方法 (総収入/固定費)",
                style: TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              subtitle: Text(
                isEveryMonth ? "毎月◯日" : "カレンダー",
                style: TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              trailing: Switch(
                value: isEveryMonth,
                onChanged: (bool val) {
                  if (!isPaidUser) {
                    _showUpgradeDialog(context);
                    return;
                  }
                  ref.read(settingsViewModelProvider.notifier)
                      .setCalendarModeForIncomeFixed(!val);
                },
                activeColor: Colors.blue,
              ),
            ),
            const Divider(),

            // --------------------------------------------------
            // 水道代2ヶ月に1度
            ListTile(
              onTap: () {
                // 元通り => 無料ユーザー => 課金ページ誘導
                if (!isPaidUser) {
                  _showUpgradeDialog(context);
                  return;
                }
                ref.read(settingsViewModelProvider.notifier)
                    .setWaterBillBimonthly(!isBimonthly);
              },
              title: Text(
                "水道代を2ヶ月に1度追加する",
                style: TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              subtitle: Text(
                "ONにすると、固定費に「水道代」と入力したら2ヶ月ごとに自動追加します",
                style: TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              trailing: Switch(
                value: isBimonthly,
                onChanged: (bool val) {
                  if (!isPaidUser) {
                    _showUpgradeDialog(context);
                    return;
                  }
                  ref.read(settingsViewModelProvider.notifier).setWaterBillBimonthly(val);
                },
                activeColor: Colors.blue,
              ),
            ),
            const Divider(),

            // --------------------------------------------------
            // 「種類のカテゴリーを増やす」は削除

            // --------------------------------------------------
            // 「種類を追加」 => プレミアムのみ
            ListTile(
              title: Text(
                "種類を追加",
                // 無料/ベーシック => グレー表示
                // プレミアム => 黒表示
                style: TextStyle(
                  color: (subscriptionStatus == 'premium')
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
              subtitle: types.isEmpty
                  ? Padding(
                padding: const EdgeInsets.only(left:8.0),
                child: Text(
                  "追加された種類はありません",
                  style: TextStyle(
                    color: (subscriptionStatus == 'premium')
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),
              )
                  : Padding(
                padding: const EdgeInsets.only(left:8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: types.map((type) {
                    return Row(
                      children: [
                        Icon(
                          type['icon'],
                          color: (subscriptionStatus == 'premium')
                              ? Colors.black
                              : Colors.grey,
                        ),
                        const SizedBox(width:8),
                        Text(
                          type['name'],
                          style: TextStyle(
                            color: (subscriptionStatus == 'premium')
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              onTap: () {
                // premium => 実行
                // basic/free => ダイアログ (誘導なし)
                if (subscriptionStatus == 'premium') {
                  _addType(context, ref);
                } else {
                  _showPremiumRequiredDialog(context);
                }
              },
            ),
            const Divider(),

            // --------------------------------------------------
            // 金額データの並び順
            ListTile(
              title: const Text("金額データの並び順"),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: sortOrder,
                        onChanged: (value) {
                          ref.read(sortOrderProvider.notifier).updateSortOrder(value!);
                          ref.read(incomeViewModelProvider.notifier).sortItems(value);
                          ref.read(fixedCostViewModelProvider.notifier).sortItems(value);
                        },
                      ),
                      const Text("下に追加"),
                    ],
                  ),
                  const SizedBox(width:16),
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: sortOrder,
                        onChanged: (value) {
                          ref.read(sortOrderProvider.notifier).updateSortOrder(value!);
                          ref.read(incomeViewModelProvider.notifier).sortItems(value);
                          ref.read(fixedCostViewModelProvider.notifier).sortItems(value);
                        },
                      ),
                      const Text("上に追加"),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // --------------------------------------------------
            // 全データ消去
            ListTile(
              title: const Text("全データ消去"),
              subtitle: const Padding(
                padding: EdgeInsets.only(left:8.0),
                child: Text("すべてのデータを消去して初期状態に戻します。"),
              ),
              trailing: GestureDetector(
                onTap: () {
                  int newDay = 1;
                  _confirmResetData(context, ref, newDay);
                },
                child: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // カレンダーピッカー
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
    return picked;
  }

  void _selectStartDay(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final selectedDay = ref.read(startDayProvider);
    final initialDate = DateTime(now.year, now.month, selectedDay);
    final firstDate = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final lastDate = DateTime(now.year, now.month, lastDay);

    final pickedDate = await showMyDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      if (pickedDate.day != selectedDay) {
        _updateStartDay(ref, pickedDate.day);
      } else {
        print("日付に変更はありません");
      }
    } else {
      print("ユーザーがキャンセルしました");
    }
  }

  void _updateStartDay(WidgetRef ref, int newDay) {
    ref.read(startDayProvider.notifier).setStartDay(newDay);
    print("開始日が更新されました: $newDay 日");

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, newDay);
    final endDate = calculateEndDate(startDate);

    ref.read(expenseViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    ref.read(fixedCostViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    ref.read(incomeViewModelProvider.notifier).filterByDateRange(startDate, endDate);

    final budgetPeriodMessage =
        "${startDate.month}月${startDate.day}日から${endDate.month}月${endDate.day}日までを管理します";
    ref.read(budgetPeriodProvider.notifier).state = budgetPeriodMessage;

    print("管理期間メッセージ: $budgetPeriodMessage");
  }

  // --------------------------------------------------
  // 全データ消去
  void _confirmResetData(BuildContext context, WidgetRef ref, int newDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("確認"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "全データを消去します。\nよろしいですか？",
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSecondConfirmation(context, ref, newDay);
              },
              child: const Text("OK"),
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
                _updateStartDay(ref, newDay);
                print("データがリセットされ、開始日が更新されました: $newDay");
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// リセット後 => state削除 + 無料化 + カレンダーモードに戻す
  void _resetData(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ref.read(startDayProvider.notifier).state = 1;
    // もし「種類のカテゴリーを増やす」を削除したので customCategoryProvider も削除対象
    ref.read(customCategoryProvider.notifier).state = [];
    ref.read(typeProvider.notifier).state = [];
    ref.read(pageIndexProvider.notifier).state = 1;
    ref.read(incomeViewModelProvider.notifier).state = [];
    ref.read(fixedCostViewModelProvider.notifier).state = [];
    ref.read(expenseViewModelProvider.notifier).state = [];
    ref.read(budgetPeriodProvider.notifier).state = "";

    ref.read(settingsViewModelProvider.notifier).resetToDefaultSettings();
    // バグ対応: カレンダーモードに強制
    ref.read(settingsViewModelProvider.notifier).setCalendarModeForIncomeFixed(true);

    // 課金状態=> free
    ref.read(subscriptionStatusProvider.notifier).state = 'free';
    await prefs.setString('subscription_plan', 'free');

    // Expand provider
    ref.read(incomeExpandProvider.notifier).state = false;
    ref.read(fixedCostsExpandProvider.notifier).state = false;
    ref.read(expensesExpandProvider.notifier).state = false;
  }

  // --------------------------------------------------
  // 「種類を追加」 => プレミアムのみ
  void _addType(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    // subscriptionStatus=='premium' => 実行
    if (subscriptionStatus != 'premium') {
      // basic / free => show dialog
      _showPremiumRequiredDialog(context);
      return;
    }

    // *** プレミアム => 種類追加実行
    final controller = TextEditingController();
    IconData? selectedIcon;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("種類を追加"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "種類名を入力"),
              ),
              const SizedBox(height:16),
              Wrap(
                spacing:10,
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
              onPressed: ()=>Navigator.pop(context),
              child: const Text("キャンセル"),
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
              child: const Text("追加"),
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

  // --------------------------------------------------
  // 課金関連ダイアログ (日付入力方法 / 水道代2ヶ月に1度 => 元のまま)
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("プレミアムプランにアップグレード"),
          content: const Text("この機能を利用するには課金プランへの加入が必要です。"),
          actions: [
            TextButton(
              onPressed: ()=>Navigator.pop(context),
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

  // ベーシック/無料=> 「プレミアムが必要」というだけで課金ページ誘導しない
  void _showPremiumRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("プレミアム機能"),
          content: const Text("この機能はプレミアムプラン加入が必要です。\n(現在準備中)"),
          actions: [
            TextButton(
              onPressed: ()=>Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
