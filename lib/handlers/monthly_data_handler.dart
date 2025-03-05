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

/// 既存の clearMonthlyData は削除せず
void clearMonthlyData({
  required List<Income> incomes,
  required List<FixedCost> fixedCosts,
  required List<Expense> expenses,
}) {
  // ▼ 収入リセット
  for (int i = 0; i < incomes.length; i++) {
    if (incomes[i].isRemember) {
      incomes[i] = incomes[i].copyWith(
        date: DateTime.now(),
        amount: incomes[i].amount,
      );
    } else {
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

/// finalizeMonth:
///   - userTriggered==true で初めて残額を貯金に合算 & metadata保存 & clearMonthlyData実行
Future<void> finalizeMonth(WidgetRef ref) async {
  final incomes = ref.read(incomeViewModelProvider);
  final fixedCosts = ref.read(fixedCostViewModelProvider);
  final expenses = ref.read(expenseViewModelProvider);

  final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
  final totalFixed  = fixedCosts.fold(0.0, (sum, f) => sum + f.amount);
  final totalSpent  = expenses.fold(0.0, (sum, e) => sum + e.amount);

  // 浪費
  final wasteTotal  = expenses.where((e) => e.isWaste).fold<double>(0, (sum, e) => sum + e.amount);
  final nonWaste    = totalSpent - wasteTotal;
  final remainingBalance = totalIncome - totalFixed - totalSpent;

  final sp = await SharedPreferences.getInstance();
  final oldSaving   = sp.getDouble("start_of_month_saving") ?? 0.0;
  final goalSaving  = sp.getDouble("savings_goal") ?? 0.0;

  // 貯金カード
  final savingCard = fixedCosts.firstWhereOrNull((fc) => fc.title == "貯金");
  final thisMonthSaving = savingCard?.amount ?? 0.0;

  // monthly_dataに保存する newTotalSaving
  double newTotalSaving = thisMonthSaving;

  final subscription = ref.read(subscriptionStatusProvider);
  final isPaidUser = (subscription=='basic' || subscription=='premium');

  // SharedPreferencesのフラグ => ユーザーが手動で月次リセットしたか
  final userTriggered = sp.getBool('isUserTriggeredFinalize') ?? false;

  // userTriggered==trueなら 残額を貯金に合算
  if (userTriggered) {
    if (remainingBalance > 0 && savingCard != null) {
      newTotalSaving = thisMonthSaving + remainingBalance;
      // copyWithで更新
      final updatedSaving = savingCard.copyWith(amount: newTotalSaving);
      ref.read(fixedCostViewModelProvider.notifier).updateFixedCost(updatedSaving);
      // メダル判定
      await ref.read(medalViewModelProvider.notifier).checkAndAwardMedal(
        totalIncome: totalIncome,
        remainingBalance: remainingBalance,
        oldSaving: oldSaving,
        newSaving: thisMonthSaving,
        isPaidUser: isPaidUser,
      );
    }
  }


  // metadata: userTriggered==trueの時だけ設定。 falseなら null
  Map<String,dynamic>? metadata;
  if (userTriggered) {
    metadata = {
      'wasteTotal'      : wasteTotal,
      'totalSpent'      : totalSpent,
      'nonWaste'        : nonWaste,
      'goalSaving'      : goalSaving,
      'thisMonthSaving' : thisMonthSaving,
      'totalSaving'     : newTotalSaving,
    };
  }

  // 課金ユーザーなら保存
  if (isPaidUser) {
    final uid = sp.getString('firebase_uid') ?? 'dummy';
    final now = DateTime.now();
    final yyyyMM = '${now.year}${now.month.toString().padLeft(2, '0')}';
    final repo = ref.read(firebaseRepositoryProvider);

    await repo.saveMonthlyData(
      uid: uid,
      yyyyMM: yyyyMM,
      incomes: incomes,
      fixedCosts: fixedCosts,
      expenses: expenses,
      metadata: metadata, // userTriggered==false => null
    );
  }

  // userTriggered==true => clear
  if (userTriggered) {
    clearMonthlyData(
      incomes: incomes,
      fixedCosts: fixedCosts,
      expenses: expenses,
    );
    await sp.setBool('isUserTriggeredFinalize', false);
  }

  // 次回 oldSaving更新
  await sp.setDouble('start_of_month_saving', newTotalSaving);
}
