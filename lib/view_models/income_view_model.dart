import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/income.dart';

class IncomeViewModel extends StateNotifier<List<Income>> {
  IncomeViewModel(this.ref) : super([]);

  final Ref ref;

  // データの保存
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('incomes', jsonData);
  }

  // データの復元
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('incomes');
    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => Income.fromJson(e)).toList();
    }
  }

  // 収入データを追加
  void addItem(Income income) {
    state = [...state, income];
    saveData();
  }

  // 収入データを削除
  void removeItem(Income income) {
    state = state.where((item) => item != income).toList();
    saveData();
  }

  // 収入データを並び替え
  void sortItems(bool isAscending) {
    state = [...state]
      ..sort((a, b) => isAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));
  }

  void filterByDateRange(DateTime startDate, DateTime endDate) {
    try {
      state = state.where((item) {
        final date = item.date; // 直接プロパティにアクセス
        return date.isAfter(startDate) && date.isBefore(endDate);
      }).toList();
    } catch (e) {
      print("Error in filterByDateRange: $e");
    }
  }
}

final incomeViewModelProvider =
StateNotifierProvider<IncomeViewModel, List<Income>>((ref) {
  return IncomeViewModel(ref);
});
