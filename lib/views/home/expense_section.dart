import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';


class ExpensesSection extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const ExpensesSection({
    super.key,
    required this.isExpanded,
    required this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesViewModelProvider);
    final totalExpenses = ref.watch(totalExpensesProvider);

    return Column(
      children: [
        GestureDetector(
          onTap: onExpandToggle,
          child: Container(
            height: MediaQuery.of(context).size.height / 20,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('使った金額', style: TextStyle(fontSize: 18)),
                Text('${totalExpenses.toStringAsFixed(0)} 円'),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ListView.builder(
            shrinkWrap: true,
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return ListTile(
                title: Text(expense.title),
                subtitle: Text('${expense.amount.toStringAsFixed(0)} 円'),
              );
            },
          ),
      ],
    );
  }
}
