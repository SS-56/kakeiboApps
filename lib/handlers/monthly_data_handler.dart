import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';

// ▼ 追加: medal_view_model を使ってメダル判定
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';

/// 既存のクリア処理
void clearMonthlyData({
  required List<Income> incomes,
  required List<FixedCost> fixedCosts,
  required List<Expense> expenses,
}) {
  // 収入のリセット
  for (int i = 0; i < incomes.length; i++) {
    if (incomes[i].isRemember) {
      incomes[i] = incomes[i].copyWith(date: DateTime.now());
      // 記憶フラグON => スキップ
      continue;
    }
    // それ以外 => amount=0, メモ等リセット
    incomes[i] = Income(
      id: '', // id再生成 or そのままでもOK
      title: incomes[i].title,
      amount: 0,
      date: DateTime.now(),
      memo: '',
      isRemember: false,
    );
  }

  // 固定費のリセット
  for (int i = 0; i < fixedCosts.length; i++) {
    if (fixedCosts[i].isRemember) {
      fixedCosts[i] = fixedCosts[i].copyWith(date: DateTime.now());
      continue;
    }
    fixedCosts[i] = FixedCost(
      id: '',
      title: fixedCosts[i].title,
      amount: 0,
      date: DateTime.now(),
      memo: '',
      isRemember: false,
    );
  }

  // 支出のリセット
  for (int i = 0; i < expenses.length; i++) {
    expenses[i] = Expense(
      id: '',
      title: expenses[i].title,
      amount: 0,
      date: DateTime.now(),
      memo: '',
      isWaste: false,
    );
  }
}

/// 例: 月次処理(締め)で「クリア+メダル判定」を行う関数
/// - refから現在の収支を取得 -> どの程度貯金を使ったか判定 -> medalViewModelでメダル付与
/// - その後 clearMonthlyDataでデータをリセット
Future<void> finalizeMonth(WidgetRef ref) async {
  // 1) 現在のデータ一覧取得
  final incomes = ref.read(incomeViewModelProvider);
  final fixedCosts = ref.read(fixedCostViewModelProvider);
  final expenses = ref.read(expenseViewModelProvider);

  // 2) 収支計算
  final totalIncome = incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
  final totalFixed  = fixedCosts.fold<double>(0.0, (sum, f) => sum + f.amount);
  final totalSpent  = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  final remainingBalance = totalIncome - totalFixed - totalSpent;

  // 3) 課金状態
  final subscriptionStatus = ref.read(subscriptionStatusProvider);
  final isPaidUser =
  (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

  // 4) 貯金のBefore/Afterを求める (例: 全固定費中「title==貯金」のものが対象)
  //    ここでは "oldSaving" は「先月開始時の貯金額」を想定 -> SharedPrefs等に保存しておく
  //    "newSaving" は今の金額
  double oldSaving = 0; // TODO: 先月開始時に記録していた値を読み込む
  final savingCard = fixedCosts.firstWhere(
        (fc) => fc.title == '貯金',
    orElse: () => FixedCost(id:'', title:'', amount:0, date:DateTime.now(),memo:'',isRemember:false),
  );
  final newSaving = savingCard.amount; // 今の貯金

  // 5) メダル判定 => checkAndAwardMedal
  await ref.read(medalViewModelProvider.notifier).checkAndAwardMedal(
    totalIncome: totalIncome,
    remainingBalance: remainingBalance,
    oldSaving: oldSaving,
    newSaving: newSaving,
    isPaidUser: isPaidUser,
  );

  // 6) 月次リセット (既存関数)
  clearMonthlyData(
    incomes: incomes,
    fixedCosts: fixedCosts,
    expenses: expenses,
  );

  // 7) 今の newSaving を次の月の oldSaving に使う => 保管しておく
  //    ex: SharedPreferencesなど
  // final prefs = await SharedPreferences.getInstance();
  // await prefs.setDouble('start_of_month_saving', newSaving);

  // 終了
}
