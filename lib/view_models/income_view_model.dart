import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import '../providers/page_providers.dart';
import '../repositories/firebase_repository.dart';
import 'package:collection/collection.dart'; // 追加

class IncomeViewModel extends StateNotifier<List<Income>> {
  final Ref ref;
  final FirebaseRepository _repository;

  List<Income> savedIncomes = []; // ✅ **保存された収入データ**

  IncomeViewModel(this.ref, this._repository) : super([]) {
    loadData();
  }

  List<Income> get data => state;

  // ✅ **データの保存**
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    // includeId: true でIDを含めて保存
    final jsonData = jsonEncode(state.map((e) => e.toJson(includeId: true)).toList());

    await prefs.setString('incomes', jsonData);
    print('Incomes saved: $jsonData');

    // ✅ **保存された収入データも Firebase に保存**
    // for (var income in savedIncomes) {
    //   await _repository.saveIncomeCard(income);
    // }
  }

  // ✅ **データのロード**
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('incomes');
    print('Loading incomes: $jsonString');

    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => Income.fromJson(e)).toList();
      print('Loaded incomes: $state');
    } else {
      print('No incomes found in SharedPreferences.');
    }

    // ✅ **Firebase から保存済みの収入データを取得**
    // savedIncomes = await _repository.getSavedIncomeCards();
    //
    // // ✅ **ロード後に `state` に統合（保存データは常に残る）**
    // state = [...savedIncomes, ...state];
  }

  // ✅ **収入データを追加**
  void addItem(Income income) async {
    if(income.title == "取り崩し") {
      income = income.copyWith(isRemember: false);
    }
    final startDate = _getStartDate();
    if (income.date.isBefore(startDate)) {
      return; // 開始日より前のデータを無視
    }
    state = [...state, income];
    await saveData();
  }

  // ✅ **特定の収入を「保存」する**
  Future<void> saveIncome(Income income) async {
    savedIncomes.add(income);
    await _repository.saveIncomeCard(income);
  }

  // ✅ **開始日を取得**
  DateTime _getStartDate() {
    final startDay = ref.read(startDayProvider);
    final now = DateTime.now();
    return DateTime(now.year, now.month, startDay);
  }

  // ✅ **収入データを削除**
  void removeItem(Income income) {
    state = state.where((item) => item != income).toList();
    // もし削除されたのが "取り崩し" なら
    if (income.title == "取り崩し") {
      // inc.amount 分だけ "貯金" カードに戻す
      final fixedCosts = ref.read(fixedCostViewModelProvider);
      final saving = fixedCosts.firstWhereOrNull((fixedCosts) => fixedCosts.title == "貯金",
      );
      if (saving != null) {
        final newSaving = saving.amount + income.amount;
        ref.read(fixedCostViewModelProvider.notifier).updateFixedCost(
          saving.copyWith(amount: newSaving, isRemember: false),
        );
      }
    }
    saveData();
  }

  // ✅ **収入データを並び替え**
  void sortItems(bool isAscending) {
    state.sort((a, b) =>
    isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
  }

  void filterByDateRange(DateTime startDate, DateTime endDate) {
    state = state.where((item) {
      final date = item.date;
      return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
    }).toList();
    saveData();
  }

  /// ✅ **全ての収入データを削除**
  void clearAllIncome() {
    state = [];
  }

  // ★ ここで更新メソッドを定義 ★
  void updateIncome(Income updated) {
    if(updated.title == "取り崩し") {
      updated = updated.copyWith(isRemember: false);
    }
    state = [
      for (final income in state)
        if (income.id == updated.id) updated else income
    ];
    saveData();
  }
}

// ✅ **プロバイダーの更新**
final incomeViewModelProvider =
StateNotifierProvider<IncomeViewModel, List<Income>>((ref) {
  final repository = ref.read(firebaseRepositoryProvider);
  return IncomeViewModel(ref, repository);
});
