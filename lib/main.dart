import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/services/shared_preferences_service.dart';
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

  final prefs = await SharedPreferences.getInstance();
  print('Starting App...');
  await debugSharedPreferences();
  final container = ProviderContainer();

  // 状態保持のためのフラグ
  bool isDataLoaded = false;
  int initialPageIndex = prefs.getInt('page_index') ?? 1;

  try {
    print('SharedPreferences content: ${prefs.getKeys()}');
    prefs.getKeys().forEach((key) {
      print('$key: ${prefs.get(key)}');
    });

    // 各データをロード
    print('Loading income data...');
    await container.read(incomeViewModelProvider.notifier).loadData();
    print('Income data loaded.');

    print('Loading fixed costs data...');
    await container.read(fixedCostViewModelProvider.notifier).loadData();
    print('Fixed costs data loaded.');

    print('Loading expenses data...');
    await container.read(expenseViewModelProvider.notifier).loadData();
    print('Expenses data loaded.');

    isDataLoaded = true; // ロード成功
  } catch (e) {
    print('Error loading data: $e');
  }

  // アプリ起動
  runApp(
    ProviderScope(
      overrides: [
        pageIndexProvider.overrideWith((ref) => initialPageIndex),
      ],
      child: MyApp(isDataLoaded: isDataLoaded),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isDataLoaded;

  const MyApp({Key? key, required this.isDataLoaded}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '家計簿アプリ',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: isDataLoaded ? const MainScaffold() : const LoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(pageIndexProvider);

    // ページリスト
    final pages = [
      const MyPage(),
      const HomePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Center(
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
