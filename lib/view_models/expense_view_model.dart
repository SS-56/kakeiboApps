import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../providers/page_providers.dart';

class ExpenseViewModel extends StateNotifier<List<Expense>> {
  final Ref ref;

  ExpenseViewModel(this.ref) : super([]);

  List<Expense> get expenses => state;

  // データの保存
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('expenses', jsonData);
  }

  // データの復元
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('expenses');
    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((e) => Expense.fromJson(e)).toList();
    }
  }

  void addItem(Expense expense) {
    // 家計簿の開始日を取得（日数を基準に計算）
    final startDaysAgo = ref.read(startDayProvider);
    final startDate = DateTime.now().subtract(Duration(days: startDaysAgo));

    // 日付バリデーション
    if (expense.date.isBefore(startDate)) {
      // 開始日以前のデータを無視
      return;
    }

    // データを状態に追加
    state = [...state, expense];

    // 保存処理を呼び出す
    saveData();
  }


  // 支出データを削除
  void removeItem(Expense expense) {
    state = state.where((item) => item != expense).toList();
    saveData();
  }

  // 支出データを並べ替え
  void sort(bool isAscending) {
    state = [
      ...state..sort((a, b) =>
      isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date))
    ];
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

final expenseViewModelProvider = StateNotifierProvider<ExpenseViewModel, List<Expense>>(
      (ref) => ExpenseViewModel(ref),
);