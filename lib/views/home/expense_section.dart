import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';

class ExpenseSection extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const ExpenseSection({
    Key? key,
    required this.isExpanded,
    required this.onExpandToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseViewModelProvider);
    final totalExpenses = expenses.fold<double>(
      0,
          (sum, expense) => sum + expense.amount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // タイトル部分
        GestureDetector(
          onTap: onExpandToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '使った金額',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Column(
            children: [
              Center(
                child: Text(
                  '${totalExpenses.toStringAsFixed(0)} 円',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return Dismissible(
                    key: ValueKey(expense.hashCode),
                    onDismissed: (_) {
                      ref.read(expenseViewModelProvider.notifier).removeItem(expense);
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        title: Text(expense.title),
                        subtitle: Text(
                          '${expense.date.year}/${expense.date.month}/${expense.date.day}',
                        ),
                        trailing: Text('${expense.amount} 円'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
      ],
    );
  }
}
