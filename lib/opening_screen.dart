import 'package:flutter/material.dart';
import 'package:yosan_de_kakeibo/views/my_page/my_setting_page.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({Key? key}) : super(key: key);

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // 1) 画面生成直後にフェードイン開始
    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1.0; // フェードイン
      });
    });

    // 2) 1秒かけてフェードインした後 → さらに3秒待機 → フェードアウト開始
    Future.delayed(const Duration(seconds: 1 + 3), () {
      if (!mounted) return;
      setState(() {
        _opacity = 0.0; // フェードアウト
      });
    });

    // 3) フェードアウト完了 (1 + 3 + 1 = 5秒後) → 画面遷移
    Future.delayed(const Duration(seconds: 1 + 3 + 1), () {
      if (!mounted) return;
      // ここで MySettingPage などへ遷移 (例)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MySettingPage(isFirstTime: true)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // アニメ付きのロゴ
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 1), // フェードに1秒
          child: Text(
            'GappsOn',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}
