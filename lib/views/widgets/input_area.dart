import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputArea extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          // 日付選択部分の修正
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
                  // 現在の時刻を保持しつつ、日付を更新
                  final now = DateTime.now();
                  final updatedDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    now.hour,
                    now.minute,
                    now.second,
                    now.millisecond,
                  );
                  print("選択された新しい日付（時刻付き）: $updatedDate");
                  onDateChange(updatedDate); // 正しい日付を通知
                }
              },
              child: Container(
                height: 48,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 修正: 表示される日付を正確に更新
                    Text('${selectedDate.year}/${selectedDate.month}/${selectedDate.day}'),
                    Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 8),

          // 種類入力
          Expanded(
            flex: 2,
            child: TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: '種類'),
            ),
          ),
          SizedBox(width: 8),

          // 金額入力
          Expanded(
            flex: 2,
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: '金額'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
              ],
            ),
          ),
          SizedBox(width: 8),

          // 追加ボタン
          IconButton(
            icon: Icon(Icons.add, color: Colors.blue),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
