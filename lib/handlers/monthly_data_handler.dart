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
// 追加: 管理開始日を取得するためのプロバイダー（家計簿の管理開始日）
import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart';
// 追加: 管理期間計算用の関数（calculateEndDate）も利用
import 'package:yosan_de_kakeibo/utils/date_utils.dart';

import '../providers/page_providers.dart';

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
///   - 自動で月次データを保存したい => userTriggered==false のときは必ず保存
///   - 手動リセット(userTriggered==true) => 貯金合算 + メダル + 全データ削除 => 保存しない
Future<void> finalizeMonth(WidgetRef ref) async {
  // 1) 現在の incomes/fixedCosts/expenses を取得
  final incomes = ref.read(incomeViewModelProvider);
  final fixedCosts = ref.read(fixedCostViewModelProvider);
  final expenses = ref.read(expenseViewModelProvider);

  // 2) 合計金額などを計算
  final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
  final totalFixed  = fixedCosts.fold(0.0, (sum, f) => sum + f.amount);
  final totalSpent  = expenses.fold(0.0, (sum, e) => sum + e.amount);

  // 浪費
  final wasteTotal  = expenses.where((e) => e.isWaste).fold<double>(0, (sum, e) => sum + e.amount);
  final nonWaste    = totalSpent - wasteTotal;
  final remainingBalance = totalIncome - totalFixed - totalSpent;

  // SharedPreferences から oldSaving や goalSaving, userTriggered などを取得
  final sp = await SharedPreferences.getInstance();
  final oldSaving   = sp.getDouble("start_of_month_saving") ?? 0.0;
  final goalSaving  = sp.getDouble("savings_goal") ?? 0.0;

  final userTriggered = sp.getBool('isUserTriggeredFinalize') ?? false;

  // Subscription (free/basic/premium)
  final subscription = ref.read(subscriptionStatusProvider);
  final isPaidUser = (subscription == 'basic' || subscription == 'premium');

  // 貯金カードがあれば取得
  final savingCard = fixedCosts.firstWhereOrNull((fc) => fc.title == "貯金");
  final thisMonthSaving = savingCard?.amount ?? 0.0;

  double newTotalSaving = thisMonthSaving;

  // (A) 手動リセット => 合算 + メダル(有料のとき) + 全データ削除
  if (userTriggered) {
    // 残額を貯金に合算
    if (remainingBalance > 0 && savingCard != null) {
      newTotalSaving = thisMonthSaving + remainingBalance;

      final updatedSaving = savingCard.copyWith(amount: newTotalSaving);
      ref.read(fixedCostViewModelProvider.notifier).updateFixedCost(updatedSaving);

      // メダル: isPaidUserなら付与
      if (isPaidUser) {
        await ref.read(medalViewModelProvider.notifier).checkAndAwardMedal(
          totalIncome: totalIncome,
          remainingBalance: remainingBalance,
          oldSaving: oldSaving,
          newSaving: thisMonthSaving,
          isPaidUser: true,
        );
      }
    }

    // 全データ削除
    clearMonthlyData(
      incomes: incomes,
      fixedCosts: fixedCosts,
      expenses: expenses,
    );
    // 全データ削除後に、購読状態も無料にリセットする
    await ref.read(subscriptionStatusProvider.notifier).resetToFree();

    // userTriggeredをオフにして終了
    await sp.setBool('isUserTriggeredFinalize', false);
    await sp.setDouble('start_of_month_saving', newTotalSaving);
    return;
  }

  // (B) 自動保存 => metadataを作って Firebaseへ
  if (isPaidUser) {
    // 修正：管理開始日を考慮した月次処理
    // 家計簿の管理開始日（startDay）は startDayProvider から取得
    final int startDay = ref.read(startDayProvider);
    final now = DateTime.now();
    DateTime periodStart;
    if (now.day >= startDay) {
      periodStart = DateTime(now.year, now.month, startDay);
    } else {
      int prevMonth = now.month - 1;
      int year = now.year;
      if (prevMonth < 1) {
        prevMonth = 12;
        year = now.year - 1;
      }
      periodStart = DateTime(year, prevMonth, startDay);
    }
    final yyyyMM = '${periodStart.year}${periodStart.month.toString().padLeft(2, '0')}';

    final repo = ref.read(firebaseRepositoryProvider);

    final metadata = {
      'wasteTotal': wasteTotal,
      'totalSpent': totalSpent,
      'nonWaste': nonWaste,
      'goalSaving': goalSaving,
      'thisMonthSaving': thisMonthSaving,
      'totalSaving': thisMonthSaving,
      'userTriggered': false,
    };

    final uid = sp.getString('firebase_uid') ?? 'dummy';
    await repo.saveMonthlyData(
      uid: uid,
      yyyyMM: yyyyMM,
      incomes: incomes,
      fixedCosts: fixedCosts,
      expenses: expenses,
      metadata: metadata,
    );

    // 修正: 自動保存時もメダル付与処理を実行する
    await ref.read(medalViewModelProvider.notifier).checkAndAwardMedal(
      totalIncome: totalIncome,
      remainingBalance: remainingBalance,
      oldSaving: oldSaving,
      newSaving: thisMonthSaving,
      isPaidUser: true,
    );
  }

  // 修正: 自動保存時も clearMonthlyData() を呼び出して月次リセットを実行
  clearMonthlyData(
    incomes: incomes,
    fixedCosts: fixedCosts,
    expenses: expenses,
  );

  // oldSaving更新 => 合算していないので thisMonthSaving のまま
  await sp.setDouble('start_of_month_saving', thisMonthSaving);
}
