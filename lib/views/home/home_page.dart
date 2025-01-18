import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/views/home/expense_section.dart';
import 'package:yosan_de_kakeibo/views/home/fixed_costs_section.dart';
import 'package:yosan_de_kakeibo/views/home/income_section.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: IncomeSection(
                    isExpanded: ref.watch(incomeExpandProvider),
                    onExpandToggle: () {
                      ref.read(incomeExpandProvider.notifier).toggle();
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: FixedCostsSection(
                    isExpanded: ref.watch(fixedCostsExpandProvider),
                    onExpandToggle: () {
                      ref.read(fixedCostsExpandProvider.notifier).toggle();
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpenseSection(
                    isExpanded: ref.watch(expenseExpandProvider),
                    onExpandToggle: () {
                      ref.read(expenseExpandProvider.notifier).toggle();
                    },
                  ),
                ),
              ],
            ),
          ),
          InputArea(
            titleController: titleController,
            amountController: amountController,
            selectedDate: selectedDate,
            onDateChange: (newDate) {
              ref.read(selectedDateProvider.notifier).state = newDate;
            },
            onAdd: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text);

              if (title.isEmpty || amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("すべての項目を入力してください")),
                );
                return;
              }

              ref.read(expenseViewModelProvider.notifier).addItem(
                Expense(
                  title: title,
                  amount: amount,
                  date: selectedDate,
                ),
              );
              titleController.clear();
              amountController.clear();
            },
          ),
        ],
      ),
    );
  }
}
