// view_models/settings_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>(
      (ref) => SettingsViewModel(),
);

class SettingsState {
  final bool useCalendarForIncomeFixed;
  final bool isWaterBillBimonthly;

  SettingsState({
    this.useCalendarForIncomeFixed = true,
    this.isWaterBillBimonthly = false, // 追加
  });

  SettingsState copyWith({ bool? useCalendarForIncomeFixed, bool? isWaterBillBimonthly, }) {
    return SettingsState(
      useCalendarForIncomeFixed: useCalendarForIncomeFixed ?? this.useCalendarForIncomeFixed,
      isWaterBillBimonthly: isWaterBillBimonthly ?? this.isWaterBillBimonthly,
    );
  }
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel() : super(SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final calMode = prefs.getBool('useCalendarForIncomeFixed') ?? true;
    state = state.copyWith(useCalendarForIncomeFixed: calMode);
  }

  Future<void> setCalendarModeForIncomeFixed(bool useCal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCalendarForIncomeFixed', useCal);
    state = state.copyWith(useCalendarForIncomeFixed: useCal);
  }
  // ★ 追加: 水道代を2ヶ月に一度にするフラグを更新するメソッド
  void setWaterBillBimonthly(bool value) {
    state = state.copyWith(isWaterBillBimonthly: value);
  }

  // ★ 追加: 無料プランの初期設定に戻す
  void resetToDefaultSettings() {
    state = SettingsState(
      useCalendarForIncomeFixed: false, // デフォルトが「毎月」なら false にする 等
      isWaterBillBimonthly: false,
      // ... 他にも課金プランでONになっていた設定を全部OFFにする
    );
  }
}
