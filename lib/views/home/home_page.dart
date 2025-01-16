import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/views/home/expense_section.dart';
import 'package:yosan_de_kakeibo/views/home/income_section.dart';
import 'package:yosan_de_kakeibo/views/home/fixed_costs_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          IncomeSection(
            isExpanded: ref.watch(incomeExpandProvider),
            onExpandToggle: () {
              ref.read(incomeExpandProvider.notifier).toggle();
            },
          ),
          const Divider(),
          FixedCostsSection(
            isExpanded: ref.watch(fixedCostsExpandProvider),
            onExpandToggle: () {
              ref.read(fixedCostsExpandProvider.notifier).toggle();
            },
          ),
          const Divider(),
          ExpensesSection(
            isExpanded: ref.watch(expensesExpandProvider),
            onExpandToggle: () {
              ref.read(expensesExpandProvider.notifier).toggle();
            },
          ),
        ],
      ),
    );
  }
}
