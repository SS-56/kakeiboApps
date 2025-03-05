import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';

// ▼ 追加: medal_view_model を使ってメダル判定
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';

/// 既存の clearMonthlyData は削除しない
void clearMonthlyData({
  required List<Income> incomes,
  required List<FixedCost> fixedCosts,
  required List<Expense> expenses,
}) {
  // ▼ 収入リセット
  for (int i = 0; i < incomes.length; i++) {
    if (incomes[i].isRemember) {
      // 記憶フラグON => そのまま保持
      incomes[i] = incomes[i].copyWith(
        date: DateTime.now(),
        amount: incomes[i].amount,
      );
    } else {
      // 記憶フラグOFF => リセット
      incomes[i] = Income(
        id: incomes[i].id,
        title: incomes[i].title,
        amount: 0,
        date: DateTime.now(),
        memo: '',
        isRemember: false,
      );
    }
  }

  // ▼ 固定費
  for (int i = 0; i < fixedCosts.length; i++) {
    if (fixedCosts[i].isRemember) {
      fixedCosts[i] = fixedCosts[i].copyWith(
        date: DateTime.now(),
        amount: fixedCosts[i].amount,
      );
    } else {
      fixedCosts[i] = FixedCost(
        id: fixedCosts[i].id,
        title: fixedCosts[i].title,
        amount: 0,
        date: DateTime.now(),
        memo: '',
        isRemember: false,
      );
    }
  }

  // ▼ 支出
  for (int i = 0; i < expenses.length; i++) {
    // 使った金額は全リセット
    expenses[i] = Expense(
      id: expenses[i].id,
      title: expenses[i].title,
      amount: 0,
      date: DateTime.now(),
      memo: '',
      isWaste: false,
    );
  }
}

/// ★ 修正版 finalizeMonth:
///   SharedPreferencesにあるフラグ「isUserTriggeredFinalize」が true のときだけ clearMonthlyData を行う
Future<void> finalizeMonth(WidgetRef ref) async {
  // 1) 現在のリスト取得
  final incomes = ref.read(incomeViewModelProvider);
  final fixedCosts = ref.read(fixedCostViewModelProvider);
  final expenses = ref.read(expenseViewModelProvider);

  // 2) 収支計算
  final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
  final totalFixed  = fixedCosts.fold(0.0, (sum, f) => sum + f.amount);
  final totalSpent  = expenses.fold(0.0, (sum, e) => sum + e.amount);
  final remainingBalance = totalIncome - totalFixed - totalSpent;

  // 3) oldSaving
  final sp = await SharedPreferences.getInstance();
  final oldSaving = sp.getDouble("start_of_month_saving") ?? 0;

  // 4) newSaving => 今の貯金
  final savingCard = fixedCosts.firstWhereOrNull((fc) => fc.title=="貯金");
  final newSaving = savingCard?.amount ?? 0;

  // 5) 課金状態
  final subscription = ref.read(subscriptionStatusProvider);
  final isPaidUser = (subscription=='basic' || subscription=='premium');

  // 6) メダル判定 => クリア前
  await ref.read(medalViewModelProvider.notifier).checkAndAwardMedal(
    totalIncome: totalIncome,
    remainingBalance: remainingBalance,
    oldSaving: oldSaving,
    newSaving: newSaving,
    isPaidUser: isPaidUser,
  );

  // 7) Firebase保存 (課金ユーザーのみ)
  if (isPaidUser) {
    final uid = sp.getString('firebase_uid') ?? 'dummy';
    final now = DateTime.now();
    final yyyyMM = '${now.year}${now.month.toString().padLeft(2,'0')}';
    final repo = ref.read(firebaseRepositoryProvider);

    await repo.saveMonthlyData(
      uid: uid,
      yyyyMM: yyyyMM,
      incomes: incomes,
      fixedCosts: fixedCosts,
      expenses: expenses,
    );
  }

  // ---------------------------
  // ★ ここが肝心: isUserTriggeredFinalize が true ならデータをクリア
  // ---------------------------
  final userTriggered = sp.getBool('isUserTriggeredFinalize') ?? false;
  if (userTriggered) {
    // クリア
    clearMonthlyData(
      incomes: incomes,
      fixedCosts: fixedCosts,
      expenses: expenses,
    );
    // フラグを戻す
    await sp.setBool('isUserTriggeredFinalize', false);
  }

  // 8) newSaving を次回 oldSaving に
  await sp.setDouble('start_of_month_saving', newSaving);
}
