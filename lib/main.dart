import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/home/home_page.dart';
import 'views/my_page/my_page.dart';
import 'views/settings/setting_page.dart';
import 'providers/page_providers.dart';

void main() {
  runApp(
    ProviderScope(
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
