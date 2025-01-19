import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';

class FixedCostViewModel extends StateNotifier<List<FixedCost>> {
  final Ref ref;

  FixedCostViewModel(this.ref) : super([]);

  // データの保存
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('fixed_costs', jsonData);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('expenses');

    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => FixedCost.fromJson(e)).toList();

      final startDay = ref.read(startDayProvider);
      if (startDay != null) {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, startDay);

        state = state.where((item) => !item.date.isBefore(startDate)).toList();
      }
    }
  }


  // 固定費データを追加
  void addItem(FixedCost fixedCost) {
    final startDate = _getStartDate();
    if (fixedCost.date.isBefore(startDate)) {
      return; // 開始日より前のデータを無視
    }
    state = [...state, fixedCost];
    saveData();
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
    try {
      state = state.where((item) {
        final date = item.date;
        return date.isAfter(startDate) && date.isBefore(endDate);
      }).toList();
    } catch (e) {
      print("Error in filterByDateRange: $e");
    }
  }

  // 開始日より前のデータをフィルタリング
  void _filterByStartDate() {
    final startDate = _getStartDate();
    state = state.where((item) => !item.date.isBefore(startDate)).toList();
  }
}

final fixedCostViewModelProvider =
StateNotifierProvider<FixedCostViewModel, List<FixedCost>>((ref) {
  return FixedCostViewModel(ref);
});
