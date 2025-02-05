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

/// ダイアログ呼び出し用の編集データ
class CardEditData {
    final String title;      // 種類
    final double amount;     // 金額
    final DateTime date;     // 日付
    final bool showMemo;     // メモ機能を使うか
    final bool showRemember; // 記憶アイコンを出すか
    final bool showWaste;    // 浪費アイコンを出すか
    final String? memo;
    final bool isRemember;
    final bool isWaste;

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

typedef OnSaveCardEdit = void Function({
  required String title,
  required double amount,
  required DateTime date,
  required String? memo,
  required bool isRemember,
  required bool isWaste,
});

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

class _CardEditDialog extends StatefulWidget {
  final CardEditData initialData;
  final OnSaveCardEdit onSave;
  const _CardEditDialog({Key? key, required this.initialData, required this.onSave}) : super(key: key);

  @override
  _CardEditDialogState createState() => _CardEditDialogState();
}

class _CardEditDialogState extends State<_CardEditDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _memoCtrl;
  late DateTime _date;
  late bool _isRemember;
  late bool _isWaste;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData.title);
    _amountCtrl = TextEditingController(text: widget.initialData.amount.toString());
    _memoCtrl   = TextEditingController(text: widget.initialData.memo ?? '');
    _date       = widget.initialData.date;
    _isRemember = widget.initialData.isRemember;
    _isWaste    = widget.initialData.isWaste;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('カード編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: '種類'),
            ),
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: '金額'),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Text('日付: ${_date.toLocal()}'.split(' ')[0]),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _date = picked;
                      });
                    }
                  },
                ),
              ],
            ),

            if (widget.initialData.showMemo)
              TextField(
                controller: _memoCtrl,
                decoration: const InputDecoration(labelText: 'メモ'),
              ),

            if (widget.initialData.showRemember)
              Row(
                children: [
                  const Text('記憶アイコン'),
                  Switch(
                    value: _isRemember,
                    onChanged: (v) => setState(() => _isRemember = v),
                  ),
                ],
              ),

            if (widget.initialData.showWaste)
              Row(
                children: [
                  const Text('浪費アイコン'),
                  Switch(
                    value: _isWaste,
                    onChanged: (v) => setState(() => _isWaste = v),
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
            final amountVal = double.tryParse(_amountCtrl.text) ?? 0;
            widget.onSave(
              title: _titleCtrl.text,
              amount: amountVal,
              date: _date,
              memo: _memoCtrl.text,
              isRemember: _isRemember,
              isWaste: _isWaste,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
