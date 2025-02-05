import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';

void clearMonthlyData({
  required List<Income> incomes,
  required List<FixedCost> fixedCosts,
  required List<Expense> expenses,
}) {
  // 例：収入のリセット
  for (int i = 0; i < incomes.length; i++) {
      if (incomes[i].isRemember) {
        incomes[i] = incomes[i].copyWith(date: DateTime.now());
        // 記憶フラグがONの場合はスキップ
        continue;
      }
  // それ以外はリセット（メモや浪費フラグ等も消す）
  incomes[i] = Income(
  title: incomes[i].title,
  amount: 0,
  date: DateTime.now(),
        memo: '',
        isRemember: false,
  );
  }

  // 例：固定費のリセット
  for (int i = 0; i < fixedCosts.length; i++) {
      if (fixedCosts[i].isRemember) {
        fixedCosts[i] = fixedCosts[i].copyWith(date: DateTime.now());
        continue;
      }
  fixedCosts[i] = FixedCost(
  title: fixedCosts[i].title,
  amount: 0,
  date: DateTime.now(),
        memo: '',
        isWaste: false,
        isRemember: false,
  );
  }

  // 例：支出のリセット
  for (int i = 0; i < expenses.length; i++) {

  expenses[i] = Expense(
  title: expenses[i].title,
  amount: 0,
  date: DateTime.now(),
        memo: '',
        isWaste: false,
  );
  }
}
