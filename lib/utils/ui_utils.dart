import 'package:flutter/material.dart';

class UIUtils {
  /// 共通エラーダイアログの表示
  static void showErrorDialog(BuildContext context, String message, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? "エラー"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// 成功時のダイアログ
  static void showSuccessDialog(BuildContext context, String message, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? "成功"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// 全画面ローディングオーバーレイの表示
  static void showLoadingOverlay(BuildContext context, {String? message}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      pageBuilder: (_, __, ___) {
        return Stack(
          children: [
            Container(
              color: Colors.black.withOpacity(0.5),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 全画面オーバーレイを閉じる
  static void hideOverlay(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// 全画面エラーメッセージオーバーレイの表示
  static void showErrorOverlay(BuildContext context, String errorMessage) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (_, __, ___) {
        return Stack(
          children: [
            Container(
              color: Colors.black.withOpacity(0.5),
            ),
            Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('閉じる'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 汎用ダイアログ（任意のUIを表示可能）
  static void showCustomDialog(BuildContext context, Widget customContent, {String? title}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        content: customContent,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("閉じる"),
          ),
        ],
      ),
    );
  }
}
