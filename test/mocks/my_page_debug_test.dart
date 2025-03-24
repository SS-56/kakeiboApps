import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/handlers/monthly_data_handler.dart';

class MyPageDebug extends ConsumerWidget {
  const MyPageDebug({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("デバッグ用画面")),
      body: Center(
        child: ElevatedButton(
          child: const Text("デバッグ: 月次リセット実行"),
          onPressed: () async {
            // SharedPreferences の isUserTriggeredFinalize を true にセット
            final sp = await SharedPreferences.getInstance();
            await sp.setBool('isUserTriggeredFinalize', true);

            // 月次リセット処理を呼び出す
            await finalizeMonth(ref);

            // 結果確認用にダイアログ表示
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("月次リセット完了"),
                content: const Text("購読状態が無料（free）にリセットされました。"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
