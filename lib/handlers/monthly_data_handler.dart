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
        isRemember: false, id: '',
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
        isRemember: false, id: '',
  );
  }

  // 例：支出のリセット
  for (int i = 0; i < expenses.length; i++) {

  expenses[i] = Expense(
  title: expenses[i].title,
  amount: 0,
  date: DateTime.now(),
        memo: '',
        isWaste: false, id: '',
  );
  }

  // handlers/monthly_data_handler.dart
  void handleMonthlyRollover({
    required List<FixedCost> fixedCosts,
    // ... incomes, expenses
    required DateTime newMonthStart,
  }) {
    // 1) 既存のクリア・リセットなど
    // 2) 記憶フラグがONのカードだけ新しい月にコピー
    for (final fc in fixedCosts) {
      if (fc.isRemember) {
        // dayOfMonthがnullならfc.date.dayを使う
        final day = fc.dayOfMonth ?? fc.date.day;

        final nextMonthDate = DateTime(
          newMonthStart.year,
          newMonthStart.month,
          day,
        );
        // 既に翌月にあるかチェックして、なければ追加
        // 例: ここで fixedCosts.add(...) ではなく
        // ViewModelの addItem(...) 相当を呼ぶ
        final newCard = fc.copyWith(
          date: nextMonthDate,
          // memoなど同じ
        );
        // 追加
        // e.g. ref.read(fixedCostViewModelProvider.notifier).addItem(newCard)
      }
    }
  }
}
