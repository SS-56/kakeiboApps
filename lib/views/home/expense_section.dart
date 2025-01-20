import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';

final expensesExpandProvider = StateProvider<bool>((ref) => false);

class ExpenseSection extends StatelessWidget {
  final WidgetRef ref;

  const ExpenseSection({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseViewModelProvider);
    final isAscending = ref.watch(sortOrderProvider);
    final sortedExpenses = List.from(expenses)
      ..sort((a, b) => isAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));

    final totalExpenses =
    sortedExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    return Column(
      children: [
        // タイトル部分
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(expensesExpandProvider.notifier).state =
                  !ref.read(expensesExpandProvider.notifier).state;
                },
                child: Container(
                  height: MediaQuery.of(context).size.height / 20,
                  color: Colors.grey[10],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '使った金額',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        ref.watch(expensesExpandProvider)
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                      ),
                    ],
                  ),
                ),
              ),
              if (ref.watch(expensesExpandProvider))
                SizedBox(
                  height: MediaQuery.of(context).size.height / 20,
                  child: Center(
                    child: Text(
                      '${totalExpenses.toStringAsFixed(0)} 円',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 支出リスト
        Expanded(
          child: ListView.builder(
            itemCount: sortedExpenses.length,
            itemBuilder: (context, index) {
              final expense = sortedExpenses[index];
              return Dismissible(
                key: ValueKey(expense),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  ref
                      .read(expenseViewModelProvider.notifier)
                      .removeItem(expense);
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${expense.date.year}/${expense.date.month}/${expense.date.day}',
                        ),
                        Text(expense.title),
                      ],
                    ),
                    title: Center(
                      child: Text(
                        '${expense.amount.toStringAsFixed(0)} 円',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.settings, color: Colors.grey),
                      onPressed: () {
                        // 設定ボタンの動作（必要に応じて実装）
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
