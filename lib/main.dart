import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/page_providers.dart';
import 'views/home/home_page.dart';
import 'views/my_page/my_page.dart';
import 'views/settings/setting_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase 初期化完了");

  // SharedPreferences 初期化
  final prefs = await SharedPreferences.getInstance();
  final initialPageIndex = prefs.getInt('page_index') ?? 1;

  // アプリ起動
  runApp(
    ProviderScope(
      overrides: [
        pageIndexProvider.overrideWith((ref) => initialPageIndex), // 初期値を直接提供
      ],
      child: const MyApp(),
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
      locale: const Locale('ja'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'), // ✅ 日本語対応
        Locale('en'), // ✅ 念のため英語も追加
      ],
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 現在のページインデックス
    final currentIndex = ref.watch(pageIndexProvider);

    // ページリスト
    final pages = [
      const MyPage(),
      const HomePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.cyan[800],
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
