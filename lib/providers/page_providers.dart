import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';



final pageIndexProvider = StateProvider<int>((ref) => 1);

// 並び替えプロバイダー
final sortOrderProvider = StateProvider<bool>((ref) => true);

final incomeDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final fixedCostsDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final expensesDateProvider = StateProvider<DateTime>((ref) => DateTime.now());


// 収入合計プロバイダー
final totalIncomeProvider = Provider<double>((ref) {
  final incomes = ref.watch(incomeViewModelProvider);
  return incomes.fold(0.0, (sum, income) => sum + income.amount);
});

// 固定費合計プロバイダー
final totalFixedCostProvider = Provider<double>((ref) {
  final fixedCosts = ref.watch(fixedCostViewModelProvider);
  return fixedCosts.fold(0.0, (sum, fixedCost) => sum + fixedCost.amount);
});

// 支出合計プロバイダー
final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseViewModelProvider);
  return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
});

// 選択された日付を管理するプロバイダー
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final startDayProvider = StateNotifierProvider<StartDayNotifier, int>((ref) {
  return StartDayNotifier(ref);
});


// StartDayNotifierの実装
class StartDayNotifier extends StateNotifier<int> {
  StartDayNotifier(this.ref) : super(DateTime.now().day);

  final Ref ref;

  // 開始日を更新するメソッド
  void updateStartDay(int newStartDay) {
    state = newStartDay;
  }
}