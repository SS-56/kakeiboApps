import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

import '../../view_models/settings_view_model.dart';

class FullScreenFixedCostsSection extends ConsumerWidget {
  const FullScreenFixedCostsSection({super.key});

  // 修正: build 毎に生成されないよう、TextEditingController を静的フィールドとして定義
  static final TextEditingController _titleController = TextEditingController();
  static final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 既存のコード内容はそのまま
    final titleController = _titleController;
    final amountController = _amountController;
    final fixedCostsDate = ref.watch(fixedCostsDateProvider);
    final settings = ref.watch(settingsViewModelProvider);

    final isPaidUser = ref.watch(
      subscriptionStatusProvider.select((s) =>
      s == SubscriptionStatusViewModel.basic ||
          s == SubscriptionStatusViewModel.premium),
    );
    // 既存のコードの先頭などで、タブレット判定を追加
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final totalFixedCosts = ref
                .watch(fixedCostViewModelProvider)
                .fold(0.0, (sum, cost) => sum + cost.amount);
            return Text('固定費合計: ${totalFixedCosts.toStringAsFixed(0)} 円', style: TextStyle(color: Colors.cyan[800]),);
          },
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  // 並び替え処理
                  final fixedCosts = ref.watch(fixedCostViewModelProvider);
                  final isAscending = ref.watch(sortOrderProvider);
                  final sortedFixedCosts = List.from(fixedCosts)
                    ..sort((a, b) => isAscending
                        ? a.date.compareTo(b.date) // 昇順
                        : b.date.compareTo(a.date)); // 降順
                  return ListView.builder(
                    itemCount: sortedFixedCosts.length,
                    itemBuilder: (context, index) {
                      final fixedCost = sortedFixedCosts[index];

                      if (isTablet) {
                        // タブレット用レイアウト：2カラム（左：日付＆タイトル、右：金額＋設定アイコン）
                        return Card(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // 左側：日付とタイトル
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 日付表示（カレンダー利用設定に応じて）
                                    settings.useCalendarForIncomeFixed
                                        ? Text(
                                      '${fixedCost.date.year}/${fixedCost.date.month}/${fixedCost.date.day}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    )
                                        : Text(
                                      '毎月${fixedCost.date.day}日',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fixedCost.title,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                // 右側：金額と設定アイコン（課金ユーザーの場合）
                                Row(
                                  children: [
                                    Text(
                                      fixedCost.amount.toStringAsFixed(0),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text("円"),
                                    if (isPaidUser)
                                      IconButton(
                                        icon: Icon(Icons.settings, color: Colors.cyan[800]),
                                        onPressed: () {
                                          _editFixed(context, ref, fixedCost);
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // 既存のスマホ用レイアウト（ListTile を使用）
                        return Dismissible(
                          key: ValueKey(fixedCost),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            final removedFixedCost = fixedCost;
                            ref.read(fixedCostViewModelProvider.notifier).removeItem(fixedCost);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${removedFixedCost.title} を削除しました。'),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: '元に戻す',
                                  onPressed: () {
                                    ref.read(fixedCostViewModelProvider.notifier).addItem(removedFixedCost);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  settings.useCalendarForIncomeFixed
                                      ? Text(
                                    '${fixedCost.date.year}/${fixedCost.date.month}/${fixedCost.date.day}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  )
                                      : Text(
                                    '毎月${fixedCost.date.day}日',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  Text(
                                    fixedCost.title,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              title: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 40.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 80,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          fixedCost.amount.toStringAsFixed(0),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text("円"),
                                    ],
                                  ),
                                ),
                              ),
                              trailing: isPaidUser
                                  ? IconButton(
                                icon: Icon(Icons.settings, color: Colors.cyan[800]),
                                onPressed: () {
                                  _editFixed(context, ref, fixedCost);
                                },
                              )
                                  : null,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            // カレンダー表示部分
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InputArea(
                titleController: titleController,
                amountController: amountController,
                selectedDate: fixedCostsDate,
                onDateChange: (newDate) {
                  ref.read(fixedCostsDateProvider.notifier).state = newDate;
                },
                onAdd: () {
                  final selectedDate = ref.read(fixedCostsDateProvider); // ここでselectedDateを取得
                  final now = DateTime.now();
                  final updatedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    now.hour,
                    now.minute,
                    now.second,
                    now.millisecond,
                  );

                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text);

                  final int startDay = ref.read(startDayProvider);
                  final DateTime startDate = DateTime(now.year, now.month, startDay);

                  // 開始日前のデータかを確認
                  if (updatedDate.isBefore(startDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('全ての項目を入力してください。')),
                    );
                    return; // 処理を中断
                  }

                  if (title.isNotEmpty && amount != null) {
                    // `addItem`メソッドでデータを追加
                    ref.read(fixedCostViewModelProvider.notifier).addItem(
                      FixedCost(
                        id: Uuid().v4(),
                        title: title,
                        amount: amount,
                        date: updatedDate,
                      ),
                    );

                    titleController.clear();
                    amountController.clear();
                    ref.read(fixedCostsDateProvider.notifier).state = DateTime.now(); // 日付リセット
                  }
                },
                useDayOfMonthPicker: !settings.useCalendarForIncomeFixed && isPaidUser,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editFixed(BuildContext context, WidgetRef ref, FixedCost fixedCost) {
    showCardEditDialog(
      context: context,
      initialData: CardEditData(
        title: fixedCost.title,
        amount: fixedCost.amount,
        date: fixedCost.date,
        showMemo: true,        // 固定費もメモ機能ON
        showRemember: true,    // 記憶アイコンON
        showWaste: false,      // 固定費に浪費はなし
        memo: fixedCost.memo,
        isRemember: fixedCost.isRemember,
        isWaste: false,
      ),
      onSave: ({
        required String title,
        required double amount,
        required DateTime date,
        required String? memo,
        required bool isRemember,
        required bool isWaste,
      }) {
        final updateFixed = fixedCost.copyWith(
          title: title,
          amount: amount,
          date: date,
          memo: memo,
          isRemember: isRemember,
        );
        ref.read(fixedCostViewModelProvider.notifier).updateFixedCost(updateFixed);

        // ViewModel の updateFixedCost

        // 変更を永続化
        ref.read(fixedCostViewModelProvider.notifier).saveData();
      },
    );
  }
}
