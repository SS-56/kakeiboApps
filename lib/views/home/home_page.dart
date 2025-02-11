import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/update_view_model.dart';
import 'package:yosan_de_kakeibo/views/home/expense_section.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_fixed_costs_section.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_income_section.dart';
import 'package:yosan_de_kakeibo/views/widgets/common_section_widget.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newStartDay = ref.watch(startDayProvider);
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final expensesDate = ref.watch(expensesDateProvider);
    final incomes = ref.watch(incomeViewModelProvider);
    final fixedCosts = ref.watch(fixedCostViewModelProvider);
    final expenses = ref.watch(expenseViewModelProvider);

    final totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
    final totalFixedCosts = fixedCosts.fold(0.0, (sum, cost) => sum + cost.amount);
    final expensesTotal = expenses.fold(0.0, (sum, expense) => sum + expense.amount);

    final remainingBalance = totalIncome - totalFixedCosts - expensesTotal;

    // アップデート確認をリッスン
    ref.listen<AsyncValue<void>>(checkForUpdateProvider, (_, state) {
      state.when(
        data: (_) {
          final isUpdateRequired = ref.watch(updateDialogProvider);
          if (isUpdateRequired) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('アップデートがあります'),
                content: const Text('新しいバージョンをダウンロードしてください。'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // プラットフォームごとのストアリンクを指定
                      final storeLink = Platform.isIOS
                          ? 'https://apps.apple.com/app/id123456789' // iOS App Store のURL
                          : 'https://play.google.com/store/apps/details?id=com.example.app'; // Android Google Play Store のURL

                      if (await canLaunchUrl(Uri.parse(storeLink))) {
                        await launchUrl(Uri.parse(storeLink));
                      } else {
                        // リンクが開けない場合のエラー処理
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ストアリンクを開けませんでした')),
                        );
                      }
                    },
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // ダイアログを閉じる
                      ref.read(updateDialogProvider.notifier).state = false; // 状態をリセット
                    },
                    child: const Text('キャンセル'),
                  ),
                ],
              ),
            );
          }
          if (newStartDay == null) {
            return;
          }
        },
        loading: () {
          // ローディング中のインジケータ表示
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        },
        error: (err, stack) {
          print("errorかな？");
          UIUtils.hideOverlay(context); // ローディングを閉じる
          UIUtils.showErrorDialog(context, "アップデート確認中にエラーが発生しました。");
        },
      );
    });

    // 起動時にアップデート確認をトリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkForUpdateProvider);
    });


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'あと ${remainingBalance.toStringAsFixed(0)} 円',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          CommonSectionWidget(
            title: '総収入',
            total: totalIncome,
            isExpanded: ref.watch(incomeExpandProvider),
            onExpand: () {
              ref.read(incomeExpandProvider.notifier).toggle();
            },
            fullScreenWidget: const FullScreenIncomeSection(),
          ),
          const Divider(height: 20, thickness: 2),
          CommonSectionWidget(
            title: '固定費',
            total: totalFixedCosts,
            isExpanded: ref.watch(fixedCostsExpandProvider),
            onExpand: () {
              ref.read(fixedCostsExpandProvider.notifier).toggle();
            },
            fullScreenWidget: const FullScreenFixedCostsSection(),
          ),
          const Divider(height: 20, thickness: 2),
          Expanded(
            child: ExpenseSection(ref: ref),
          ),
          InputArea(
            titleController: titleController,
            amountController: amountController,
            selectedDate: expensesDate,
            onDateChange: (newDate) {
              ref.read(expensesDateProvider.notifier).state = newDate;
            },
            onAdd: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text);

              if (title.isEmpty || amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("すべての項目を入力してください")),
                );
                return;
              }

              ref.read(expenseViewModelProvider.notifier).addItem(
                Expense(
                  id: const Uuid().v4(),
                  title: title,
                  amount: amount,
                  date: expensesDate,
                ),
              );
              titleController.clear();
              amountController.clear();
            },
          ),
        ],
      ),
    );
  }
}
