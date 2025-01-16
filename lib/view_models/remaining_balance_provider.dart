// 残高計算プロバイダー
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';

final remainingBalanceProvider = Provider<double>((ref) {
  final totalIncome = ref.watch(totalIncomeProvider);
  final totalFixedCosts = ref.watch(totalFixedCostProvider);
  final totalExpenses = ref.watch(totalExpensesProvider);
  return totalIncome - totalFixedCosts - totalExpenses;
});
