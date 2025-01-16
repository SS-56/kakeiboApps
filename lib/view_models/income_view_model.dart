import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/income.dart';

class IncomeViewModel extends StateNotifier<List<Income>> {
  IncomeViewModel() : super([]);

  // 収入データを追加
  void addItem(Income income) {
    state = [...state, income];
  }

  // 収入データを削除
  void removeItem(Income income) {
    state = state.where((item) => item != income).toList();
  }

  // 収入データを並び替え
  void sortItems(bool isAscending) {
    state = [...state]
      ..sort((a, b) => isAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));
  }
}

final incomeViewModelProvider =
StateNotifierProvider<IncomeViewModel, List<Income>>((ref) {
  return IncomeViewModel();
});
