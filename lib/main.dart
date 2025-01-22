import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/services/shared_preferences_service.dart';
import 'views/home/home_page.dart';
import 'views/my_page/my_page.dart';
import 'views/settings/setting_page.dart';
import 'providers/page_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("update確認中");

  final prefs = await SharedPreferences.getInstance();
  print('Starting App...');
  await debugSharedPreferences();

  int initialPageIndex = prefs.getInt('page_index') ?? 1;

  // アプリ起動
  runApp(
    ProviderScope(
      overrides: [
        pageIndexProvider.overrideWith((ref) => initialPageIndex),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '家計簿アプリ',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScaffold(),
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
