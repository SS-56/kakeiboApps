import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../providers/page_providers.dart';

class ExpenseViewModel extends StateNotifier<List<Expense>> {
  final Ref ref;

  ExpenseViewModel(this.ref) : super([]);

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
    _saveToSharedPreferences();
  }


  // 支出データを削除
  void removeItem(Expense expense) {
    state = state.where((item) => item != expense).toList();
    _saveToSharedPreferences();
  }

  // 支出データを並べ替え
  void sort(bool isAscending) {
    state = [
      ...state..sort((a, b) =>
      isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date))
    ];
  }

  // SharedPreferencesへの保存
  Future<void> _saveToSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = state.map((expense) => expense.toJson()).toList();
    await prefs.setString('expenses', jsonEncode(jsonData));
  }

  // SharedPreferencesからの読み込み
  Future<void> loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('expenses');
    if (jsonString != null) {
      final List<dynamic> jsonData = jsonDecode(jsonString);
      state = jsonData.map((item) => Expense.fromJson(item)).toList();
    }
  }
}

final expensesViewModelProvider = StateNotifierProvider<ExpenseViewModel, List<Expense>>(
      (ref) => ExpenseViewModel(ref),
);