import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

class FullScreenFixedCostsSection extends ConsumerWidget {
  const FullScreenFixedCostsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final fixedCostsDate = ref.watch(fixedCostsDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final totalFixedCosts = ref
                .watch(fixedCostViewModelProvider)
                .fold(0.0, (sum, cost) => sum + cost.amount);
            return Text('固定費合計: ${totalFixedCosts.toStringAsFixed(0)} 円');
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                // 並び替え処理
                final fixedCosts = ref.watch(fixedCostViewModelProvider);
                final isAscending = ref.watch(sortOrderProvider);
                final sortedFixedCosts = List.from(fixedCosts)
                  ..sort((a, b) => isAscending
                      ? a.date.compareTo(b.date) // 昇順
                      : b.date.compareTo(a.date)); // 降順
                return ListView.builder(
                  itemCount: sortedFixedCosts.length,
                  itemBuilder: (context, index) {
                    final fixedCost = sortedFixedCosts[index];
                    return Dismissible(
                      key: ValueKey(fixedCost),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        ref
                            .read(fixedCostViewModelProvider.notifier)
                            .removeItem(fixedCost);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('${fixedCost.title} が削除されました')),
                        );
                      },
                      child: Card(
                        margin:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${fixedCost.date.year}/${fixedCost.date.month}/${fixedCost.date.day}', // 日付
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                fixedCost.title,
                                style: TextStyle(fontSize: 16),
                              ), // 種類
                            ],
                          ),
                          title: Center(
                            child: Text(
                              '${fixedCost.amount.toStringAsFixed(0)} 円', // 金額
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // カレンダー表示部分
          InputArea(
            titleController: titleController,
            amountController: amountController,
            selectedDate: fixedCostsDate,
            onDateChange: (newDate) {
              ref.read(fixedCostsDateProvider.notifier).state = newDate;
            },
            onAdd: () {
              final selectedDate = ref.read(fixedCostsDateProvider);  // ここでselectedDateを取得
              final now = DateTime.now();
              final updatedDate = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                now.hour,
                now.minute,
                now.second,
                now.millisecond,
              );

              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text);

              if (title.isNotEmpty && amount != null) {
                // `addItem`メソッドでデータを追加
                ref.read(fixedCostViewModelProvider.notifier).addItem(
                  FixedCost(
                    title: title,
                    amount: amount,
                    date: updatedDate,
                  ),
                );

                titleController.clear();
                amountController.clear();
                ref.read(fixedCostsDateProvider.notifier).state = DateTime.now(); // 日付リセット
              }
            },
          ),
        ],
      ),
    );
  }
}
