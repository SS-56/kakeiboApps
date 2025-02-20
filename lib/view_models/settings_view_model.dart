// view_models/settings_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>(
      (ref) => SettingsViewModel(),
);

class SettingsState {
  final bool useCalendarForIncomeFixed;
  // 他の設定もあれば追加

  SettingsState({ this.useCalendarForIncomeFixed = true });

  SettingsState copyWith({ bool? useCalendarForIncomeFixed }) {
    return SettingsState(
      useCalendarForIncomeFixed: useCalendarForIncomeFixed ?? this.useCalendarForIncomeFixed,
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
}
