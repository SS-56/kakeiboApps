// ※このコードは説明目的のサンプルです。
// 実際の実装ではユーザー設定から取得するようにしてください。
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('JPY') { // 初期値を 'JPY' に変更
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString('currency');
    if (savedCurrency != null) {
      state = savedCurrency;
    }
  }

  Future<void> setCurrency(String newCurrency) async {
    state = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', newCurrency);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>(
      (ref) => CurrencyNotifier(),
);
