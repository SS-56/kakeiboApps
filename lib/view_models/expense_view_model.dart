import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../providers/page_providers.dart';

class ExpenseViewModel extends StateNotifier<List<Expense>> {
  final Ref ref;

  ExpenseViewModel(this.ref) : super([]);

  List<Expense> get expenses => state;
  bool _isDataLoaded = false;

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('expenses', jsonData); // 支出専用のキーを使用
    print('Expenses saved: $jsonData');
  }


  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('expenses'); // 修正: 正しいキーを使用
    print('Loading expenses from SharedPreferences: $jsonString');

    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => Expense.fromJson(e)).toList();
      print('Loaded expenses: $state');
    } else {
      print('No expenses found in SharedPreferences.');
    }
  }

  // 支出データを追加
  void addItem(Expense expense) async {
    final startDate = _getStartDate();
    // 日付バリデーション
    if (expense.date.isBefore(startDate)) {
      return;
    }
    // データを状態に追加
    state = [...state, expense];
    await saveData();
  }

  // 開始日を取得
  DateTime _getStartDate() {
    final startDay = ref.read(startDayProvider);
    final now = DateTime.now();
    return DateTime(now.year, now.month, startDay);
  }

  // 支出データを削除
  void removeItem(Expense expense) {
    state = state.where((item) => item != expense).toList();
    saveData();
  }

  // 支出データを並べ替え
  void sort(bool isAscending) {
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
}

final expenseViewModelProvider =
    StateNotifierProvider<ExpenseViewModel, List<Expense>>(
  (ref) => ExpenseViewModel(ref),
);
