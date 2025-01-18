import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateNotifier for section expand/collapse
class ExpandNotifier extends StateNotifier<bool> {
  ExpandNotifier() : super(false); // 初期状態は格納（false）

  void toggle() {
    state = !state; // 状態を反転
    print("ExpandNotifier state toggled: $state"); // デバッグログ
  }
}

// Provider for expand states
final incomeExpandProvider = StateNotifierProvider<ExpandNotifier, bool>(
      (ref) => ExpandNotifier(),
);

final fixedCostsExpandProvider = StateNotifierProvider<ExpandNotifier, bool>(
      (ref) => ExpandNotifier(),
);

final expenseExpandProvider = StateNotifierProvider<ExpandNotifier, bool>(
      (ref) => ExpandNotifier(),
);