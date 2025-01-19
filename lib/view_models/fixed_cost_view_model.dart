import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';

class FixedCostViewModel extends StateNotifier<List<FixedCost>> {
  FixedCostViewModel(this.ref) : super([]);

  final Ref? ref;

  // データの保存
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('fixed_costs', jsonData);
  }

  // データの読み込み
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('fixed_costs');
    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => FixedCost.fromJson(e)).toList();
    }
  }

  // 固定費データを追加
  void addItem(FixedCost fixedCost) {
    state = [...state, fixedCost];
    saveData();
  }

  // 固定費データを削除
  void removeItem(FixedCost fixedCost) {
    state = state.where((item) => item != fixedCost).toList();
    saveData();
  }

  // 固定費データを並び替え
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

final fixedCostViewModelProvider =
StateNotifierProvider<FixedCostViewModel, List<FixedCost>>((ref) {
  return FixedCostViewModel(ref);
});
