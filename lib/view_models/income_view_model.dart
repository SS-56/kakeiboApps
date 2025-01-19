import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import '../providers/page_providers.dart';

class IncomeViewModel extends StateNotifier<List<Income>> {
  final Ref ref;

  IncomeViewModel(this.ref) : super([]);

  // データの保存
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('incomes', jsonData);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('incomes');
    print('Loading incomes: $jsonString'); // ログを追加

    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => Income.fromJson(e)).toList();
      print('Loaded incomes: $state'); // ロード後の状態を確認

      final startDay = ref.read(startDayProvider);
      if (startDay != null) {
        final now = DateTime.now();
        final startDate = DateTime(now.year, now.month, startDay);

        state = state.where((item) => !item.date.isBefore(startDate)).toList();
        print('Filtered incomes by start day: $state'); // フィルタ後の状態を確認
      }
    }
  }

  // 収入データを追加
  void addItem(Income income) async {
    final startDate = _getStartDate();
    if (income.date.isBefore(startDate)) {
      return; // 開始日より前のデータを無視
    }
    state = [...state, income];
    await saveData();
  }

  // 開始日を取得
  DateTime _getStartDate() {
    final startDay = ref.read(startDayProvider);
    final now = DateTime.now();
    return DateTime(now.year, now.month, startDay);
  }

  // 収入データを削除
  void removeItem(Income income) {
    state = state.where((item) => item != income).toList();
    saveData();
  }

  // 収入データを並び替え
  void sortItems(bool isAscending) {
    state.sort((a, b) =>
        isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
  }

  // 指定された期間でフィルタリング
  void filterByDateRange(DateTime startDate, DateTime endDate) {
    state = state.where((item) {
      final date = item.date;
      return date.isAfter(startDate) && date.isBefore(endDate);
    }).toList();
  }

  // 開始日以前のデータをフィルタリング
  void _filterByStartDate() {
    final startDate = _getStartDate();
    state = state.where((item) => !item.date.isBefore(startDate)).toList();
  }
}

final incomeViewModelProvider =
    StateNotifierProvider<IncomeViewModel, List<Income>>((ref) {
  return IncomeViewModel(ref);
});
