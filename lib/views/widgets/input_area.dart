import 'package:flutter/cupertino.dart';
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

  // ★ ここが鍵: 課金プラン (毎月◯日) かどうか
  final bool useDayOfMonthPicker;

  const InputArea({
    super.key,
    required this.titleController,
    required this.amountController,
    required this.selectedDate,
    required this.onDateChange,
    required this.onAdd,
    this.useDayOfMonthPicker = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDay = ref.watch(startDayProvider);
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, startDay);

    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // ▼ 日付選択
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () async {
                if (useDayOfMonthPicker) {
                  // ★ 課金プラン: 「毎月◯日」Picker
                  final pickedDay = await _pickDayOfMonthCupertino(context, selectedDate);
                  if (pickedDay != null) {
                    // ◎ ここで “pickedDay” が “開始日（startDay）” より小さいなら「翌月」扱いにする
                    final now = DateTime.now();
                    final startDay = ref.read(startDayProvider); // 例: 16
                    final currentYear = selectedDate.year;
                    final currentMonth = selectedDate.month;

                    // ▼ デフォルトは「同じ月」
                    int newYear = currentYear;
                    int newMonth = currentMonth;

                    // ◎ pickedDay < startDay ⇒ 翌月へ
                    if (pickedDay < startDay) {
                      newMonth += 1;
                      if (newMonth > 12) {
                        newMonth = 1;
                        newYear += 1;
                      }
                    }

                    // newDate => 月をずらしたり、dayをpickedDayに更新
                    final newDate = DateTime(
                      newYear,
                      newMonth,
                      pickedDay,
                      now.hour,
                      now.minute,
                      now.second,
                      now.millisecond,
                      now.microsecond,
                    );

                    // ▼ 既存の判定ロジックをそのまま
                    final startDate = DateTime(now.year, now.month, ref.read(startDayProvider));
                    if (newDate.isBefore(startDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('開始日より前の日付は入力できません')),
                      );
                    } else {
                      onDateChange(newDate);
                    }
                  }
                } else {
                  // ★ 無料プラン or 使った金額: showDatePicker
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final now = DateTime.now();
                    final startDate = DateTime(now.year, now.month, ref.read(startDayProvider));
                    if (pickedDate.isBefore(startDate)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('開始日より前の日付は入力できません')),
                      );
                    } else {
                      onDateChange(pickedDate);
                    }
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
                      useDayOfMonthPicker
                          ? '毎月${selectedDate.day}日'
                          : '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                    ),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ▼ 種類入力
          Expanded(
            flex: 2,
            child: TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '種類'),
            ),
          ),
          const SizedBox(width: 8),

          // ▼ 金額入力
          Expanded(
            flex: 2,
            child: TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: '金額'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}$')),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ▼ 追加ボタン
          IconButton(
            icon: const Icon(Icons.add, color: Colors.cyan),
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim());

              if (title.isEmpty || amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('全てのデータを入力してください')),
                );
                return;
              }

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
                return;
              }

              onAdd();
              onDateChange(DateTime.now());
            },
          ),
        ],
      ),
    );
  }

  Future<int?> _pickDayOfMonthCupertino(BuildContext context, DateTime selectedDate) async {
    // 例: selectedDate の月
    final year = selectedDate.year;
    final month = selectedDate.month;

    // ★ 当月の日数を取得
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    int selectedIndex = 0;

    return showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // 上部にDoneボタン
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  // ユーザーがDoneを押したとき → day = selectedIndex + 1
                  Navigator.pop(context, selectedIndex + 1);
                },
                child: Text("完了"),
              ),
            ),
            // CupertinoPicker本体
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32.0,
                onSelectedItemChanged: (index) {
                  selectedIndex = index;
                },
                children: List<Widget>.generate(
                  daysInMonth,
                      (index) => Center(child: Text("${index + 1}日")),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
