import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';

class FixedCostViewModel extends StateNotifier<List<FixedCost>> {
  final Ref ref;

  FixedCostViewModel(this.ref) : super([]);

  List<FixedCost> get data => state;

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonData = jsonEncode(state.map((e) => e.toJson(includeId: true)).toList());

    await prefs.setString('fixed_costs', jsonData); // 固定費専用のキーを使用
    print('Fixed costs saved: $jsonData');
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('fixed_costs'); // 修正: 正しいキーを使用
    print('Loading fixed costs from SharedPreferences: $jsonString');

    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => FixedCost.fromJson(e)).toList();
      print('Loaded fixed costs: $state');
    } else {
      print('No fixed costs found in SharedPreferences.');
    }
  }
  // 固定費データを追加
  void addItem(FixedCost fixedCost) async {
    final startDate = _getStartDate();
    if (fixedCost.date.isBefore(startDate)) {
      return; // 開始日より前のデータを無視
    }
    state = [...state, fixedCost];
    await saveData();
  }

  // 開始日を取得
  DateTime _getStartDate() {
    final startDay = ref.read(startDayProvider);
    final now = DateTime.now();
    return DateTime(now.year, now.month, startDay);
  }

  // 固定費データを削除
  void removeItem(FixedCost fixedCost) {
    state = state.where((item) => item != fixedCost).toList();
    // もし削除されたカードが "貯金" だったら、対応する "取り崩し" Cards を全部消す
    if (fixedCost.title == "貯金") {
      // 取り崩しカードを削除
      // incomeViewModelProvider から stateを取得し、"取り崩し"タイトルのカードをまとめて削除
      final incomes = ref.read(incomeViewModelProvider);
      final removeTargets = incomes.where((inc) => inc.title == "取り崩し").toList();

      // remove each
      for (final inc in removeTargets) {
        ref.read(incomeViewModelProvider.notifier).removeItem(inc);
      }
    }
    saveData();
  }

  // 固定費データを並び替え
  void sortItems(bool isAscending) {
    state = [...state]
      ..sort((a, b) => isAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));
  }

  // 指定された期間でフィルタリング
  void filterByDateRange(DateTime startDate, DateTime endDate) {
    state = state.where((item) {
      final date = item.date;
      return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
          (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
    }).toList();
    print('Filtered fixedCost: $state');
  }
  /// 全ての固定費を削除
  void clearAllFixedCosts() {
    state = [];
  }
  // ★ ここで更新メソッドを定義 ★
  void updateFixedCost(FixedCost updated) {
    state = [
      for (final fixedCost in state)
        if (fixedCost.id == updated.id) updated else fixedCost
    ];
    saveData();
  }

  double get savingsTotal {
    // 「titleが"貯金"」のカード合計
    return state
        .where((fc) => fc.title == "貯金")
        .fold<double>(0.0, (sum, fc) => sum + fc.amount);
  }
}

final fixedCostViewModelProvider =
StateNotifierProvider<FixedCostViewModel, List<FixedCost>>((ref) {
  return FixedCostViewModel(ref);
});

final savingsGoalProvider = StateNotifierProvider<SavingsGoalViewModel, double>(
      (ref) => SavingsGoalViewModel(),
);

class SavingsGoalViewModel extends StateNotifier<double> {
  SavingsGoalViewModel() : super(0.0) {
    loadGoal();
  }

  Future<void> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble('savings_goal') ?? 0.0;
  }

  Future<void> setGoal(double newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('savings_goal', newGoal);
    state = newGoal;
  }
}