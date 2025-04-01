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
    final types = ref.watch(typeProvider);

    // 課金状態を取得
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPaidUser =
    (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    // 日付入力方法
    final isCalendarMode =
        ref
            .watch(settingsViewModelProvider)
            .useCalendarForIncomeFixed;
    // スイッチがON => 「毎月◯日」モード
    final isEveryMonth = !isCalendarMode;

    // 水道代2ヶ月ごとのbool
    final isBimonthly = ref
        .watch(settingsViewModelProvider)
        .isWaterBillBimonthly;

    final sortOrder = ref.watch(sortOrderProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[50],
        title: Text("設定", style: TextStyle(color: Colors.cyan[800]),),
      ),
      body: ListTileTheme(
        contentPadding:
        const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        dense: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Text(
                            "現在: $startDay日",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today, color: Colors.cyan[800]),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                      child: Text(
                        ref
                            .watch(budgetPeriodProvider)
                            .isNotEmpty
                            ? ref.watch(budgetPeriodProvider)
                            : "",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.cyan[800]),

            // 日付入力方法(総収入/固定費)
            ListTile(
              onTap: () {
                if (!isPaidUser) {
                  _showUpgradeDialog(context);
                  return;
                }
                ref
                    .read(settingsViewModelProvider.notifier)
                    .setCalendarModeForIncomeFixed(isEveryMonth);
              },
              title: Text(
                "日付入力方法 (収入/固定費)",
                style:
                TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              subtitle: Text(
                isEveryMonth ? "毎月◯日" : "カレンダー",
                style:
                TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              trailing: Switch(
                value: isEveryMonth && isPaidUser,
                onChanged: (bool val) {
                  if (!isPaidUser) {
                    _showUpgradeDialog(context);
                    return;
                  }
                  ref
                      .read(settingsViewModelProvider.notifier)
                      .setCalendarModeForIncomeFixed(!val);
                },
                inactiveThumbColor: Colors.black,
                activeColor: Colors.cyan[800],
              ),
            ),
            Divider(color: Colors.cyan[800]),

            // 水道代2ヶ月に1度
            ListTile(
              onTap: () {
                if (!isPaidUser) {
                  _showUpgradeDialog(context);
                  return;
                }
                ref
                    .read(settingsViewModelProvider.notifier)
                    .setWaterBillBimonthly(!isBimonthly);
              },
              title: Text(
                "水道代を2ヶ月に1度追加する",
                style:
                TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              subtitle: Text(
                "ONにすると、固定費に「水道代」と入力したら2ヶ月ごとに自動追加します",
                style:
                TextStyle(color: isPaidUser ? Colors.black : Colors.grey),
              ),
              trailing: Switch(
                value: isBimonthly && isPaidUser,
                onChanged: (bool val) {
                  if (!isPaidUser) {
                    _showUpgradeDialog(context);
                    return;
                  }
                  ref
                      .read(settingsViewModelProvider.notifier)
                      .setWaterBillBimonthly(val);
                },
                inactiveThumbColor: Colors.black,
                activeColor: Colors.cyan[800],
              ),
            ),
            Divider(color: Colors.cyan[800]),

            // 「種類を追加」 => プレミアムのみ
            ListTile(
              title: Text(
                "種類をアイコン化する",
                style: TextStyle(
                  color: (subscriptionStatus == 'premium')
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
              subtitle: types.isEmpty
                  ? Text(
                "アイコン表示に切り替える",
                style: TextStyle(
                  color: (subscriptionStatus == 'premium')
                      ? Colors.black
                      : Colors.grey,
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
                          color: (subscriptionStatus == 'premium')
                              ? Colors.black
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['name'],
                          style: TextStyle(
                            color:
                            (subscriptionStatus == 'premium')
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
                // premium => 種類を追加
                // basic/free => ダイアログで「プレミアムが必要」
                if (subscriptionStatus == 'premium') {
                  _addType(context, ref);
                } else {
                  _showPremiumRequiredDialog(context);
                }
              },
            ),
            Divider(color: Colors.cyan[800]),

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
                        activeColor: Colors.cyan[800],
                        onChanged: (value) {
                          ref
                              .read(sortOrderProvider.notifier)
                              .updateSortOrder(value!);
                          ref
                              .read(incomeViewModelProvider.notifier)
                              .sortItems(value);
                          ref
                              .read(fixedCostViewModelProvider.notifier)
                              .sortItems(value);
                        },
                      ),
                      const Text("下に追加"),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: sortOrder,
                        activeColor: Colors.cyan[800],
                        onChanged: (value) {
                          ref
                              .read(sortOrderProvider.notifier)
                              .updateSortOrder(value!);
                          ref
                              .read(incomeViewModelProvider.notifier)
                              .sortItems(value);
                          ref
                              .read(fixedCostViewModelProvider.notifier)
                              .sortItems(value);
                        },
                      ),
                      Text("上に追加"),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.cyan[800]),
          ],
        ),
      ),
    );
  }

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
      locale: const Locale('ja'),
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Colors.cyan, // ✅ 選択した日付の背景をシアンに
              onPrimary: Colors.white, // ✅ 選択した日付の文字色を白に
              onSurface: Colors.black, // ✅ 通常のテキストの色をシアンに
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.cyan[800], // ✅ 「キャンセル」「OK」ボタンの色をシアンに
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    return picked;
  }

  /// ★ 修正: 「pickedDateがnullでなければ、常にダイアログ」を表示
  ///         つまり日付が前後にかかわらず必ず _showEarlierDateConfirmDialog を呼ぶ
  void _selectStartDay(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final selectedDay = ref.read(startDayProvider); // 例: 16

    // ここが「家計簿開始日の当月の日付」として使われる
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
      // ★★ 常にダイアログを出す (日付が前か後か関係なし)
      _showEarlierDateConfirmDialog(context, ref, pickedDate.day);
    } else {
      print("ユーザーがキャンセルしました");
    }
  }

  void _showEarlierDateConfirmDialog(
      BuildContext context,
      WidgetRef ref,
      int newDay,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("開始日を変更します"),
          content: const Text(
            "この日付を選択すると、開始日より前のデータが消去されます。\nよろしいですか？",
          ),
          actions: [
            TextButton(
              onPressed: () {
                // ★ ダイアログを閉じる => 必ず dialogContext を使う
                Navigator.pop(dialogContext);
              },
              child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800]),),
            ),
            TextButton(
              onPressed: () {
                // ダイアログを閉じてから startDay更新
                Navigator.pop(dialogContext);
                _updateStartDay(ref, newDay);
              },
              child: Text("OK", style: TextStyle(color: Colors.cyan[800]),),
            ),
          ],
        );
      },
    );
  }

  void _updateStartDay(WidgetRef ref, int newDay) {
    final oldDay = ref.read(startDayProvider); // 現在の開始日
    print("開始日が更新されます: old=$oldDay → new=$newDay");

    // ★ ここで「newDay < oldDay」かどうかを判定して、さらに別のダイアログを出す
    //   => これも既存の文言を変えず、最低限の修正のみ
    if (newDay < oldDay) {
      // 前倒し => "開始日より前の日付を選択" ダイアログ表示
      _showConfirmEarlierStartDay(ref, newDay);
    } else {
      // それ以外 => そのまま適用
      _applyNewStartDay(ref, newDay);
    }
  }

  void _showConfirmEarlierStartDay(WidgetRef ref, int newDay) {
    showDialog(
      context: ref.context, // ConsumerWidgetではref.contextも可能
      builder: (_) =>
          AlertDialog(
            title: const Text("開始日より前の日付を選択しました"),
            content: const Text(
              "この日付を選ぶと、開始日より前のカードが消去される可能性があります。\nよろしいですか？",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ref.context),
                child: Text(
                  "キャンセル", style: TextStyle(color: Colors.cyan[800]),),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ref.context);
                  _applyNewStartDay(ref, newDay);
                },
                child: Text("OK", style: TextStyle(color: Colors.cyan[800]),),
              ),
            ],
          ),
    );
  }

  void _applyNewStartDay(WidgetRef ref, int newDay) {
    ref.read(startDayProvider.notifier).setStartDay(newDay);
    print("開始日が更新されました: $newDay 日");

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, newDay);
    final endDate = calculateEndDate(startDate);

    // 「開始日より前のデータ」はフィルタリングで実質消去
    ref.read(expenseViewModelProvider.notifier).filterByDateRange(
        startDate, endDate);
    ref.read(fixedCostViewModelProvider.notifier).filterByDateRange(
        startDate, endDate);
    ref.read(incomeViewModelProvider.notifier).filterByDateRange(
        startDate, endDate);

    final budgetPeriodMessage =
        "${startDate.month}月${startDate.day}日から${endDate.month}月${endDate
        .day}日までを管理します";
    ref
        .read(budgetPeriodProvider.notifier)
        .state = budgetPeriodMessage;

    print("管理期間メッセージ: $budgetPeriodMessage");
  }

  // 「種類を追加」 => プレミアムのみ
  void _addType(BuildContext context, WidgetRef ref) {
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);

    if (subscriptionStatus != 'premium') {
      _showPremiumRequiredDialog(context);
      return;
    }

    final controller = TextEditingController();
    IconData? selectedIcon;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("種類をアイコン表示する"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "種類名を入力"),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  _iconChoice(Icons.local_dining, "食材", selectedIcon, (icon) {
                    selectedIcon = icon;
                  }),
                  _iconChoice(Icons.checkroom, "服", selectedIcon, (icon) {
                    selectedIcon = icon;
                  }),
                  _iconChoice(
                      Icons.local_drink, "ボトル", selectedIcon, (icon) {
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
              child: Text(
                "キャンセル", style: TextStyle(color: Colors.cyan[800]),),
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
              child: Text("追加", style: TextStyle(color: Colors.cyan[800]),),
            ),
          ],
        );
      },
    );
  }

  Widget _iconChoice(IconData icon, String label, IconData? selectedIcon,
      ValueChanged<IconData> onSelected) {
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
      barrierDismissible: false, // 画面外タップで閉じないようにしたければ
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("課金プラン限定機能"),
          content: const Text(
              "この機能を利用するにはベーシック以上\nの課金プランへの加入が必要です。"),
          actions: [
            TextButton(
              onPressed: () {
                // ダイアログを閉じるだけ
                Navigator.pop(dialogContext);
              },
              child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800])),
            ),
            TextButton(
              onPressed: () {
                // ダイアログを閉じる → その後に SubscriptionPage へ遷移
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SubscriptionPage()),
                );
              },
              child: Text("課金プランを確認する", style: TextStyle(color: Colors.cyan[800]),),
            ),
          ],
        );
      },
    );
  }


  void _showPremiumRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text("プレミアム課金プラン\n限定機能"),
            content: const Text(
                "この機能はプレミアムプラン加入が必要です。\n(現在準備中)"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // ここも dialogContext
                },
                child: Text("OK", style: TextStyle(color: Colors.cyan[800]),),
              ),
            ],
          ),
    );
  }
}
