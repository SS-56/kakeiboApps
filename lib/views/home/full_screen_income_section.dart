import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

import '../../view_models/settings_view_model.dart';

class FullScreenIncomeSection extends ConsumerWidget {
  const FullScreenIncomeSection({super.key});

  // 追加修正: build 毎に生成されないよう、コントローラーを静的フィールドとして定義
  static final TextEditingController _titleController = TextEditingController();
  static final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // build 内では既存のコードをそのまま利用
    final titleController = _titleController;
    final amountController = _amountController;
    final incomeDate = ref.watch(incomeDateProvider);
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
            final totalIncome = ref
                .watch(incomeViewModelProvider)
                .fold(0.0, (sum, income) => sum + income.amount);
            return Text('収入: ${totalIncome.toStringAsFixed(0)} 円', style: TextStyle(color: Colors.cyan[800]),);
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
                  final incomes = ref.watch(incomeViewModelProvider);
                  final isAscending = ref.watch(sortOrderProvider);
                  final sortedIncomes = List.from(incomes)
                    ..sort((a, b) => isAscending
                        ? a.date.compareTo(b.date) // 昇順
                        : b.date.compareTo(a.date)); // 降順
                  return ListView.builder(
                    itemCount: sortedIncomes.length,
                    itemBuilder: (context, index) {
                      final income = sortedIncomes[index];

                      if (isTablet) {
                        // タブレット用レイアウト：2カラム表示（左：日付＆タイトル、右：金額＋設定アイコン）
                        return Dismissible(
                          key: ValueKey(income),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            final removedIncome = income;
                            ref.read(incomeViewModelProvider.notifier).removeItem(income);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${removedIncome.title} を削除しました。'),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: '元に戻す',
                                  onPressed: () {
                                    ref.read(incomeViewModelProvider.notifier).addItem(removedIncome);
                                  },
                                ),
                              ),
                            );
                          },
                          child: Card(
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
                                      settings.useCalendarForIncomeFixed
                                          ? Text(
                                        '${income.date.year}/${income.date.month}/${income.date.day}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      )
                                          : Text(
                                        '毎月${income.date.day}日',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        income.title,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  // 右側：金額と（課金ユーザーなら）設定アイコン
                                  Row(
                                    children: [
                                      Text(
                                        income.amount.toStringAsFixed(0),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text("円"),
                                      if (isPaidUser)
                                        IconButton(
                                          icon: Icon(Icons.settings, color: Colors.cyan[800]),
                                          onPressed: () => _editIncome(context, ref, income),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        // 既存のスマホ用レイアウト（ListTile を使用）
                        return Dismissible(
                          key: ValueKey(income),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) {
                            final removedIncome = income;
                            ref.read(incomeViewModelProvider.notifier).removeItem(income);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${removedIncome.title} を削除しました。'),
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: '元に戻す',
                                  onPressed: () {
                                    ref.read(incomeViewModelProvider.notifier).addItem(removedIncome);
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
                                  if (settings.useCalendarForIncomeFixed)
                                    Text(
                                      '${income.date.year}/${income.date.month}/${income.date.day}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    )
                                  else
                                    Text(
                                      '毎月${income.date.day}日',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  Text(
                                    income.title,
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
                                      Flexible(
                                        child: Text(
                                          income.amount.toStringAsFixed(0),
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
                                onPressed: () => _editIncome(context, ref, income),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InputArea(
                titleController: titleController,
                amountController: amountController,
                selectedDate: incomeDate,
                onDateChange: (newDate) {
                  ref.read(incomeDateProvider.notifier).state = newDate;
                },
                onAdd: () {
                  final selectedDate = ref.read(incomeDateProvider);
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
                    return;
                  }

                  if (title.isNotEmpty && amount != null) {
                    ref.read(incomeViewModelProvider.notifier).addItem(
                      Income(
                        id: Uuid().v4(),
                        title: title,
                        amount: amount,
                        date: updatedDate,
                      ),
                    );
                    titleController.clear();
                    amountController.clear();
                    ref.read(incomeDateProvider.notifier).state = DateTime.now();
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

  void _editIncome(BuildContext context, WidgetRef ref, Income income) {
    showCardEditDialog(
      context: context,
      initialData: CardEditData(
        title: income.title,
        amount: income.amount,
        date: income.date,
        showMemo: true,
        showRemember: true,
        showWaste: false,
        memo: income.memo,
        isRemember: income.isRemember,
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
        final updateIncome = income.copyWith(
          title: title,
          amount: amount,
          date: date,
          memo: memo,
          isRemember: isRemember,
        );

        ref.read(incomeViewModelProvider.notifier).updateIncome(updateIncome);
        ref.read(incomeViewModelProvider.notifier).saveData();
      },
    );
  }
}
