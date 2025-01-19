import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'views/home/home_page.dart';
import 'views/my_page/my_page.dart';
import 'views/settings/setting_page.dart';
import 'providers/page_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferencesを初期化してロード
  final prefs = await SharedPreferences.getInstance();

  // プロバイダーコンテナを使用して状態を復元
  final container = ProviderContainer();

  // 状態復元
  final expenseViewModel = container.read(expenseViewModelProvider.notifier);
  await expenseViewModel.loadData();

  final fixedCostViewModel = container.read(fixedCostViewModelProvider.notifier);
  await fixedCostViewModel.loadData();

  final incomeViewModel = container.read(incomeViewModelProvider.notifier);
  await incomeViewModel.loadData();

  final SubscriptionStatusViewModel = container.read(subscriptionStatusProvider.notifier);
  await SubscriptionStatusViewModel.loadStatus();


  // 必要な状態をロード
  final initialPageIndex = prefs.getInt('page_index') ?? 1; // デフォルト値は1
  runApp(
    ProviderScope(
      overrides: [
        pageIndexProvider.overrideWith((ref) => initialPageIndex),
        expenseViewModelProvider.overrideWith((ref) => expenseViewModel),
        fixedCostViewModelProvider.overrideWith((ref) => fixedCostViewModel),
        incomeViewModelProvider.overrideWith((ref) => incomeViewModel),
        subscriptionStatusProvider.overrideWith((ref) => SubscriptionStatusViewModel),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家計簿アプリ',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(pageIndexProvider);

    // ページリスト
    final pages = [
      const MyPage(), // マイページ（左）
      const HomePage(), // ホーム画面（真ん中）
      const SettingsPage(), // 設定画面（右）
    ];

    return Scaffold(
      body: Center( // ホーム画面が中央に表示される
        child: pages[currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(pageIndexProvider.notifier).state = index;
        },
      ),
    );
  }
}
