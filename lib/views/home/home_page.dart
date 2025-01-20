import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/views/home/expense_section.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_fixed_costs_section.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_income_section.dart';
import 'package:yosan_de_kakeibo/views/home/income_section.dart';
import 'package:yosan_de_kakeibo/views/home/fixed_costs_section.dart';
import 'package:yosan_de_kakeibo/views/widgets/common_section_widget.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newStartDay = ref.watch(startDayProvider);

    // 開始日がロード中の場合
    if (newStartDay == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final expensesDate = ref.watch(expensesDateProvider);
    final incomes = ref.watch(incomeViewModelProvider);
    final fixedCosts = ref.watch(fixedCostViewModelProvider);
    final expenses = ref.watch(expenseViewModelProvider);

    final totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
    final totalFixedCosts = fixedCosts.fold(0.0, (sum, cost) => sum + cost.amount);
    final expensesTotal = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    final remainingBalance = totalIncome - totalFixedCosts - expensesTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'あと ${remainingBalance.toStringAsFixed(0)} 円',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          CommonSectionWidget(
            title: '総収入',
            total: totalIncome,
            isExpanded: ref.watch(incomeExpandProvider),
            onExpand: () {
              ref.read(incomeExpandProvider.notifier).toggle();
            },
            fullScreenWidget: const FullScreenIncomeSection(),
          ),
          const Divider(height: 20, thickness: 2),
          CommonSectionWidget(
            title: '固定費',
            total: totalFixedCosts,
            isExpanded: ref.watch(fixedCostsExpandProvider),
            onExpand: () {
              ref.read(fixedCostsExpandProvider.notifier).toggle();
            },
            fullScreenWidget: const FullScreenFixedCostsSection(),
          ),
          const Divider(height: 20, thickness: 2),
          Expanded(
            child: ExpenseSection(ref: ref),
          ),
          InputArea(
            titleController: titleController,
            amountController: amountController,
            selectedDate: expensesDate,
            onDateChange: (newDate) {
              ref.read(expensesDateProvider.notifier).state = newDate;
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
                  date: expensesDate,
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
