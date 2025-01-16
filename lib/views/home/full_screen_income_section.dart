import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

class FullScreenIncomeSection extends ConsumerWidget {
  const FullScreenIncomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                        ref.read(incomeViewModelProvider.notifier).removeItem(income);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${income.title} が削除されました')),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${income.date.year}/${income.date.month}/${income.date.day}', // 日付
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                income.title, // 種類
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          title: Center(
                            child: Text(
                              '${income.amount.toStringAsFixed(0)} 円', // 金額
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.settings, color: Colors.grey), // 歯車アイコン
                            onPressed: () {
                              // 編集機能を追加する場合はここに実装
                            },
                          ),
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
            selectedDate: ref.watch(selectedDateProvider),
            onDateChange: (newDate) {
              ref.read(selectedDateProvider.notifier).state = newDate;
            },
            onAdd: () {
              final selectedDate = ref.read(selectedDateProvider);
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
                  SnackBar(content: Text('開始日より前の日付のデータは入力できません')),
                );
                return; // 処理を中断
              }

              if (title.isNotEmpty && amount != null) {
                ref.read(incomeViewModelProvider.notifier).addItem(
                  Income(
                    title: title,
                    amount: amount,
                    date: updatedDate,
                  ),
                );
                titleController.clear();
                amountController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
