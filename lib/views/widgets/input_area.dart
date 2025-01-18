import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                  onDateChange(pickedDate); // 日付を更新
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
              onAdd();
              onDateChange(DateTime.now()); // 日付を現在の日付にリセット
              }),
        ],
      ),
    );
  }
}
