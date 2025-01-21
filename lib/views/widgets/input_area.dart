import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';

class InputArea extends ConsumerWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChange;
  final VoidCallback onAdd;

  const InputArea({
    super.key,
    required this.titleController,
    required this.amountController,
    required this.selectedDate,
    required this.onDateChange,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDay = ref.watch(startDayProvider); // 開始日をRiverpodで取得
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, startDay); // 開始日を設定

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 日付選択
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  // 開始日より前の日付を選択した場合
                  if (pickedDate.isBefore(startDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('開始日より前の日付は入力できません')),
                    );
                  } else {
                    onDateChange(pickedDate); // 正しい日付を選択した場合はコールバックを呼び出し
                  }
                }
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                    ),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 種類入力
          Expanded(
            flex: 2,
            child: TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '種類'),
            ),
          ),
          const SizedBox(width: 8),

          // 金額入力
          Expanded(
            flex: 2,
            child: TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '金額'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 追加ボタン
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim());

              // 入力チェック: すべてのデータが入力されているか
              if (title.isEmpty || amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('全てのデータを入力してください')),
                );
                return; // 処理を中断
              }

              // 入力チェック: 日付が開始日より前か
              final updatedDate = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                now.hour,
                now.minute,
                now.second,
                now.millisecond,
              );

              if (updatedDate.isBefore(startDate)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('開始日より前の日付は入力できません')),
                );
                return; // 処理を中断
              }

              // データが有効な場合はonAddを実行
              onAdd();
              onDateChange(DateTime.now()); // 日付を現在の日付にリセット
            },
          ),
        ],
      ),
    );
  }
}
