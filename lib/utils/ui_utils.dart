import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// ダイアログに渡す初期データ (UI表示の設定も含む)
class CardEditData {
  final String title;      // 種類
  final double amount;     // 金額
  final DateTime date;     // 日付

  final bool showMemo;     // メモ機能を使うか
  final bool showRemember; // 記憶アイコンを出すか
  final bool showWaste;    // 浪費アイコンを出すか

  final String? memo;      // メモ初期値
  final bool isRemember;   // 記憶アイコン 初期値
  final bool isWaste;      // 浪費アイコン 初期値

  CardEditData({
    required this.title,
    required this.amount,
    required this.date,
    required this.showMemo,
    required this.showRemember,
    required this.showWaste,
    this.memo,
    this.isRemember = false,
    this.isWaste = false,
  });
}

/// 「保存」ボタン押下時のコールバック型
typedef OnSaveCardEdit = void Function({
required String title,
required double amount,
required DateTime date,
required String? memo,
required bool isRemember,
required bool isWaste,
});

/// ダイアログ呼び出し関数
Future<void> showCardEditDialog({
  required BuildContext context,
  required CardEditData initialData,
  required OnSaveCardEdit onSave,
}) {
  return showDialog(
    context: context,
    builder: (_) => _CardEditDialog(
      initialData: initialData,
      onSave: onSave,
    ),
  );
}

/// ダイアログ本体: StatefulWidget
class _CardEditDialog extends StatefulWidget {
  final CardEditData initialData;
  final OnSaveCardEdit onSave;

  const _CardEditDialog({
    Key? key,
    required this.initialData,
    required this.onSave,
  }) : super(key: key);

  @override
  _CardEditDialogState createState() => _CardEditDialogState();
}

/// State部
class _CardEditDialogState extends State<_CardEditDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _memoCtrl;

  late DateTime _localDate;
  late bool _localIsRemember;
  late bool _localIsWaste;

  @override
  void initState() {
    super.initState();
    // 1) initStateで一回だけ初期化
    _titleCtrl = TextEditingController(text: widget.initialData.title);
    _amountCtrl = TextEditingController(
      text: widget.initialData.amount.toString(),
    );
    _memoCtrl = TextEditingController(text: widget.initialData.memo ?? '');

    _localDate = widget.initialData.date;
    _localIsRemember = widget.initialData.isRemember;
    _localIsWaste = widget.initialData.isWaste;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('カード編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 日付
            Row(
              children: [
                const Text('日付: '),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _localDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _localDate = picked;
                      });
                    }
                  },
                ),
                Text('${_localDate.year}/${_localDate.month}/${_localDate.day}'),
              ],
            ),

            // 種類
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '種類'),
            ),

            // 金額
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '金額'),
            ),

            // メモ
            if (widget.initialData.showMemo)
              TextField(
                controller: _memoCtrl,
                decoration: const InputDecoration(labelText: 'メモ'),
                minLines: 4,
                maxLines: null,
              ),

            // 記憶アイコン
            if (widget.initialData.showRemember)
              Row(
                children: [
                  const Text('記憶アイコン'),
                  Switch(
                    value: _localIsRemember,
                    onChanged: (v) {
                      setState(() {
                        _localIsRemember = v;
                      });
                    },
                  ),
                ],
              ),

            // 浪費アイコン
            if (widget.initialData.showWaste)
              Row(
                children: [
                  const Text('浪費アイコン'),
                  Switch(
                    value: _localIsWaste,
                    onChanged: (v) {
                      setState(() {
                        _localIsWaste = v;
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            final parsedAmt = double.tryParse(_amountCtrl.text) ?? 0.0;
            widget.onSave(
              title: _titleCtrl.text,
              amount: parsedAmt,
              date: _localDate,
              memo: _memoCtrl.text,
              isRemember: _localIsRemember,
              isWaste: _localIsWaste,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
