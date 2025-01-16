import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';

class FixedCostViewModel extends StateNotifier<List<FixedCost>> {
  FixedCostViewModel() : super([]);

  // 固定費データを追加
  void addItem(FixedCost fixedCost) {
    state = [...state, fixedCost];
  }

  // 固定費データを削除
  void removeItem(FixedCost fixedCost) {
    state = state.where((item) => item != fixedCost).toList();
  }

  // 固定費データを並び替え
  void sortItems(bool isAscending) {
    state = [...state]
      ..sort((a, b) => isAscending
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));
  }
}

final fixedCostViewModelProvider =
StateNotifierProvider<FixedCostViewModel, List<FixedCost>>((ref) {
  return FixedCostViewModel();
});
