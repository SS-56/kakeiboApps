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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final incomeDate = ref.watch(incomeDateProvider);
    final settings = ref.watch(settingsViewModelProvider);

    final isPaidUser = ref.watch(
      subscriptionStatusProvider.select((s) =>
          s == SubscriptionStatusViewModel.basic ||
          s == SubscriptionStatusViewModel.premium),
    );

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final totalIncome = ref
                .watch(incomeViewModelProvider)
                .fold(0.0, (sum, income) => sum + income.amount);
            return Text('総収入合計: ${totalIncome.toStringAsFixed(0)} 円');
          },
        ),
      ),
      body: Column(
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
                    return Dismissible(
                      key: ValueKey(income),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // 削除処理
                        ref
                            .read(incomeViewModelProvider.notifier)
                            .removeItem(income);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${income.title} が削除されました')),
                        );
                      },
                      child: Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (settings.useCalendarForIncomeFixed)
                                // カレンダーモード → YYYY/MM/DD
                                Text(
                                  '${income.date.year}/${income.date.month}/${income.date.day}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              else
                                // 毎月◯日モード
                                Text(
                                  '毎月${income.date.day}日',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              Text(
                                income.title, // 種類
                                style: TextStyle(fontSize: 16),
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
                                      income.amount.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text("円")
                                ],
                              ),
                            ),
                          ),
                          trailing: isPaidUser
                              ? IconButton(
                                  icon:
                                      Icon(Icons.settings, color: Colors.black),
                                  onPressed: () =>
                                      _editIncome(context, ref, income),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          InputArea(
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
              final DateTime startDate =
                  DateTime(now.year, now.month, startDay);

              // 開始日前のデータかを確認
              if (updatedDate.isBefore(startDate)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('全ての項目を入力してください。')),
                );
                return; // 処理を中断
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
                ref.read(incomeDateProvider.notifier).state =
                    DateTime.now(); // 日付をリセット
              }
            },
            useDayOfMonthPicker: !settings.useCalendarForIncomeFixed,
          ),
        ],
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
