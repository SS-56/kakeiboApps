import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/utils/date_utils.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';

final pageIndexProvider = StateProvider<int>((ref) => 1);

final sortOrderProvider = StateNotifierProvider<SortOrderNotifier, bool>((ref) {
  return SortOrderNotifier();
});

class SortOrderNotifier extends StateNotifier<bool> {
  SortOrderNotifier() : super(true);

  Future<void> updateSortOrder(bool isAscending) async {
    state = isAscending;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sort_order', isAscending);
  }

  Future<void> _loadSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('sort_order') ?? true;
  }
}


final incomeDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final fixedCostsDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final expensesDateProvider = StateProvider<DateTime>((ref) => DateTime.now());


// 収入合計プロバイダー
final totalIncomeProvider = Provider<double>((ref) {
  final incomes = ref.watch(incomeViewModelProvider);
  return incomes.fold(0.0, (sum, income) => sum + income.amount);
});

// 固定費合計プロバイダー
final totalFixedCostProvider = Provider<double>((ref) {
  final fixedCosts = ref.watch(fixedCostViewModelProvider);
  return fixedCosts.fold(0.0, (sum, fixedCost) => sum + fixedCost.amount);
});

// 支出合計プロバイダー
final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseViewModelProvider);
  return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
});

// 選択された日付を管理するプロバイダー
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final startDayProvider = StateNotifierProvider<StartDayNotifier, int>((ref) {
  return StartDayNotifier(ref);
});

class StartDayNotifier extends StateNotifier<int> {
  final Ref ref;
  bool isLoading = true; // ロード中フラグ

  StartDayNotifier(this.ref) : super(1) {
    _initialize(); // 初期化時にロード処理を実行
  }

  Future<void> _initialize() async {
    ref.read(incomeViewModelProvider.notifier).loadData();
    ref.read(fixedCostViewModelProvider.notifier).loadData();
    ref.read(expenseViewModelProvider.notifier).loadData();
    await _loadStartDay();
  }

  Future<void> setStartDay(int day) async {
    state = day;

    // SharedPreferencesに保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('start_day', day);

    // 開始日を基準に管理期間を計算
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, state);
    DateTime endDate = calculateEndDate(startDate);

    // データを再ロードしてからフィルタリングを適用
    await ref.read(expenseViewModelProvider.notifier).loadData();
    _applyFilters(startDate, endDate);

    // 管理期間メッセージを更新
    _updateBudgetMessage(startDate, endDate);

    print("開始日が更新されました: $day");
  }


  /// SharedPreferencesから開始日をロード
  Future<void> _loadStartDay() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDay = prefs.getInt('start_day');

    if (savedDay != null) {
      state = savedDay;

      // 管理期間を更新
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, savedDay);
      final endDate = calculateEndDate(startDate);

      _updateBudgetMessage(startDate, endDate);
      _applyFilters(startDate, endDate);
    } else {
      print("開始日が保存されていないため、デフォルト値を使用します");
    }
  }

  /// 管理期間メッセージを更新
  void _updateBudgetMessage(DateTime startDate, DateTime endDate) {
    final budgetPeriodMessage =
        "${startDate.month}月${startDate.day}日から${endDate.month}月${endDate
        .day}日までの家計簿を管理します";
    ref
        .read(budgetPeriodProvider.notifier)
        .state = budgetPeriodMessage;
  }

  void _applyFilters(DateTime startDate, DateTime endDate) async {
    print("データをフィルタリングしています: $startDate から $endDate");

    // 総収入のフィルタリング
    ref.read(incomeViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    await ref.read(incomeViewModelProvider.notifier).saveData();

    // 固定費のフィルタリング
    ref.read(fixedCostViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    await ref.read(fixedCostViewModelProvider.notifier).saveData();

    // 支出のフィルタリング
    ref.read(expenseViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    await ref.read(expenseViewModelProvider.notifier).saveData();

    print("フィルタリングと保存が完了しました。");
  }


  Future<void> _saveFilteredData() async {
    await ref.read(incomeViewModelProvider.notifier).saveData();
    await ref.read(fixedCostViewModelProvider.notifier).saveData();
    await ref.read(expenseViewModelProvider.notifier).saveData();
    print("フィルタリング後のデータを保存しました。");
  }
}

// 通知設定プロバイダー
final notificationSettingProvider = StateNotifierProvider<NotificationSettingNotifier, bool>((ref) {
  return NotificationSettingNotifier();
});

class NotificationSettingNotifier extends StateNotifier<bool> {
  NotificationSettingNotifier() : super(false); // 初期値は通知オフ
  void toggleNotification(bool value) {
    state = value; // 状態を更新
  }
}

// データバックアッププロバイダー
final dataBackupProvider = StateNotifierProvider<DataBackupNotifier, bool>((ref) {
  return DataBackupNotifier();
});

class DataBackupNotifier extends StateNotifier<bool> {
  DataBackupNotifier() : super(false); // 初期値は同期オフ
  void toggleBackup(bool value) {
    state = value; // 状態を更新
  }
}

final typeProvider = StateNotifierProvider<TypeNotifier, List<Map<String, dynamic>>>((ref) {
  return TypeNotifier();
});

class TypeNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  TypeNotifier() : super([]) {
    _loadTypes(); // 初期化時にロード
  }

  void addType(Map<String, dynamic> type) {
    state = [...state, type]; // 新しいタイプを追加
    _saveTypes();
  }

  Future<void> _loadTypes() async {
    // SharedPreferencesなどを使用してロード
  }

  Future<void> _saveTypes() async {
    // SharedPreferencesなどを使用して保存
  }
}

final customCategoryProvider = StateNotifierProvider<CustomCategoryNotifier, List<String>>((ref) {
  return CustomCategoryNotifier();
});

class CustomCategoryNotifier extends StateNotifier<List<String>> {
  CustomCategoryNotifier() : super([]) {
    _loadCategories(); // 初期化時にロード
  }

  void addCategory(String category) {
    state = [...state, category]; // 新しいカテゴリを追加
    _saveCategories();
  }

  Future<void> _loadCategories() async {
    // SharedPreferencesなどを使用してロード
  }

  Future<void> _saveCategories() async {
    // SharedPreferencesなどを使用して保存
  }
}

final budgetPeriodProvider = StateNotifierProvider<BudgetPeriodNotifier, String>((ref) {
  return BudgetPeriodNotifier();
});

class BudgetPeriodNotifier extends StateNotifier<String> {
  BudgetPeriodNotifier() : super("") {
    _loadBudgetPeriod();
  }

  void setBudgetPeriod(String period) {
    state = period;
    _saveBudgetPeriod(period);
  }

  Future<void> _loadBudgetPeriod() async {
    // SharedPreferencesなどを使用してロード
  }

  Future<void> _saveBudgetPeriod(String period) async {
    // SharedPreferencesなどを使用して保存
  }
}






