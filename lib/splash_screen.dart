import 'package:flutter/material.dart';
import 'package:yosan_de_kakeibo/views/my_page/my_setting_page.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // シンプルにロゴを表示するだけの画面
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () {
            // ロゴタップで利用規約画面へ遷移
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MySettingPage()),
            );
          },
          child: Image.asset('assets/logo.png'), // 会社ロゴ
        ),
      ),
    );
  }
}
