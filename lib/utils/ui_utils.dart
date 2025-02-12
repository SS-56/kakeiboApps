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

/// 以下6つのProviderを用意 (autoDisposeでダイアログ閉じたら破棄されるように)
final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
final _amountProvider = StateProvider.autoDispose<double>((ref) => 0.0);
final _dateProvider = StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final _memoProvider = StateProvider.autoDispose<String?>((ref) => '');
final _rememberProvider = StateProvider.autoDispose<bool>((ref) => false);
final _wasteProvider = StateProvider.autoDispose<bool>((ref) => false);

Future<void> showCardEditDialog({
  required BuildContext context,
  required CardEditData initialData,
  required OnSaveCardEdit onSave,
}) {
  return showDialog(
    context: context,
    builder: (_) {
      return ProviderScope(
        overrides: [
          // 各Providerの初期値を上書きする
          _titleProvider.overrideWith((ref) => initialData.title),
          _amountProvider.overrideWith((ref) => initialData.amount),
          _dateProvider.overrideWith((ref) => initialData.date),
          _memoProvider.overrideWith((ref) => initialData.memo ?? ''),
          _rememberProvider.overrideWith((ref) => initialData.isRemember),
          _wasteProvider.overrideWith((ref) => initialData.isWaste),

          // onSave の注入
          _onSaveProvider.overrideWithValue(onSave),
        ],
        // ダイアログ本体をConsumerWidgetで描画
        child: const _CardEditDialog(),
      );
    },
  );
}

final _onSaveProvider = Provider.autoDispose<OnSaveCardEdit>((ref) {
  // ダミー(実際にoverrideするので呼ばれない想定)
  return ({
    required String title,
    required double amount,
    required DateTime date,
    required String? memo,
    required bool isRemember,
    required bool isWaste,
  }) {};
});

class _CardEditDialog extends ConsumerWidget {
  const _CardEditDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 各StateProviderの値を読み取る
    final titleValue = ref.watch(_titleProvider);
    final amountValue = ref.watch(_amountProvider);
    final dateValue = ref.watch(_dateProvider);
    final memoValue = ref.watch(_memoProvider);
    final rememberValue = ref.watch(_rememberProvider);
    final wasteValue = ref.watch(_wasteProvider);

    // 書き換えるときは .notifier.state に代入
    // => TextFieldやSwitchのonChangedでやる

    // onSave を呼び出すためのProvider
    final onSaveCallback = ref.read(_onSaveProvider);

    // それ以外に titleValue, amountValue は double/string だから
    // テキストフィールドとのバインドはこんな形にする
    final titleController = TextEditingController(text: titleValue);
    final amountController = TextEditingController(text: amountValue.toString());
    final memoController = TextEditingController(text: memoValue ?? '');

    return AlertDialog(
      title: const Text('カード編集 (ConsumerWidget版)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ▼ タイトル
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '種類'),
              onChanged: (value) {
                ref.read(_titleProvider.notifier).state = value;
              },
            ),

            // ▼ 金額
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '金額'),
              onChanged: (value) {
                final parsed = double.tryParse(value) ?? 0.0;
                ref.read(_amountProvider.notifier).state = parsed;
              },
            ),

            // ▼ 日付
            Row(
              children: [
                Text('日付: ${dateValue.toLocal()}'.split(' ')[0]),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateValue,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      ref.read(_dateProvider.notifier).state = picked;
                    }
                  },
                ),
                Text('${dateValue.year}/${dateValue.month}/${dateValue.day}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            // ▼ メモ(オプション)
            // ここで showMemo などのフラグを使うには、同様にProviderをoverrideしてもいいし
            // or builder引数(= constructor)を使う
            // ここでは一例として "memoValue != null" で出すと仮定
            (memoValue != null) ? TextField(
              controller: memoController,
              decoration: const InputDecoration(labelText: 'メモ'),
              onChanged: (value) {
                ref.read(_memoProvider.notifier).state = value;
              },
            ) : Container(),

            // ▼ 記憶アイコン
            Row(
              children: [
                const Text('記憶アイコン'),
                Switch(
                  value: rememberValue,
                  onChanged: (v) => ref.read(_rememberProvider.notifier).state = v,
                ),
              ],
            ),

            // ▼ 浪費アイコン
            Row(
              children: [
                const Text('浪費アイコン'),
                Switch(
                  value: wasteValue,
                  onChanged: (v) => ref.read(_wasteProvider.notifier).state = v,
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
            // 「保存」押下時、現在のProviderの値を読み取り onSaveCallback を呼ぶ
            final currentTitle = ref.read(_titleProvider.notifier).state;
            final currentAmount = ref.read(_amountProvider.notifier).state;
            final currentDate = ref.read(_dateProvider.notifier).state;
            final currentMemo = ref.read(_memoProvider.notifier).state;
            final currentRemember = ref.read(_rememberProvider.notifier).state;
            final currentWaste = ref.read(_wasteProvider.notifier).state;

            onSaveCallback(
              title: currentTitle,
              amount: currentAmount,
              date: currentDate,
              memo: currentMemo,
              isRemember: currentRemember,
              isWaste: currentWaste,
            );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
