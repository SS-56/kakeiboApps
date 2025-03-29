import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/firebase_options.dart';
import 'package:yosan_de_kakeibo/opening_screen.dart';
import 'package:yosan_de_kakeibo/views/my_page/my_setting_page.dart';
import 'providers/page_providers.dart';
import 'views/home/home_page.dart';
import 'views/my_page/my_page.dart';
import 'views/settings/setting_page.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  print("Firebase 初期化完了");

  // SharedPreferences 初期化
  final prefs = await SharedPreferences.getInstance();
  final initialPageIndex = prefs.getInt('page_index') ?? 1;

  // 利用規約の同意フラグをチェック
  final isAccepted = prefs.getBool('termsAccepted') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        pageIndexProvider.overrideWith((ref) => initialPageIndex),
      ],
      child: MyApp(isAccepted: isAccepted),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isAccepted; // 初回起動かどうかのフラグ

  const MyApp({Key? key, required this.isAccepted}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
        Locale('ja'),
        Locale('en'),
      ],
      // builder を追加して、画面サイズに応じた textScaleFactor を適用
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // 画面の短辺の長さが600dp以上なら iPad（タブレット）と判断
        final bool isTablet = mediaQuery.size.shortestSide >= 600;
        final double textScaleFactor = isTablet ? 1.5 : 1.0;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaleFactor: textScaleFactor),
          child: child!,
        );
      },
      // isAccepted=false => OpeningScreen => 2秒後 my_setting_page
      // isAccepted=true => 従来通り MainScaffold
      home: isAccepted
          ? const MainScaffold()
          : const OpeningScreen(),
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

