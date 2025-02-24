import 'dart:io';

import 'package:collection/collection.dart'; // firstWhereOrNull用
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/utils/ui_utils.dart';
import 'package:yosan_de_kakeibo/view_models/expand_notifier.dart';
import 'package:yosan_de_kakeibo/view_models/expense_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/fixed_cost_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/income_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/update_view_model.dart';
import 'package:yosan_de_kakeibo/views/home/expense_section.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_fixed_costs_section.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_income_section.dart';
import 'package:yosan_de_kakeibo/views/widgets/common_section_widget.dart';
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

// もしグローバルなダイアログ表示抑制フラグが必要なら以下を providers に定義してください
// final withdrawalDialogSuppressProvider = StateProvider<bool>((ref) => false);

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

    // 残高計算
    final totalIncome = incomes.fold(0.0, (sum, inc) => sum + inc.amount);
    final totalFixedCosts = fixedCosts.fold(0.0, (sum, fc) => sum + fc.amount);
    final totalSpent = expenses.fold(0.0, (sum, ex) => sum + ex.amount);
    final remainingBalance = totalIncome - totalFixedCosts - totalSpent;

    // アップデート確認処理（従来通り）
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
                      final storeLink = Platform.isIOS
                          ? 'https://apps.apple.com/app/id123456789'
                          : 'https://play.google.com/store/apps/details?id=com.example.app';
                      if (await canLaunchUrl(Uri.parse(storeLink))) {
                        await launchUrl(Uri.parse(storeLink));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ストアリンクを開けませんでした')),
                        );
                      }
                    },
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(updateDialogProvider.notifier).state = false;
                    },
                    child: const Text('キャンセル'),
                  ),
                ],
              ),
            );
          }
          if (newStartDay == null) return;
        },
        loading: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        },
        error: (err, stack) {
          UIUtils.hideOverlay(context);
          UIUtils.showErrorDialog(context, "アップデート確認中にエラーが発生しました。");
        },
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkForUpdateProvider);
    });

    // 課金状態の取得
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPaidUser = (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    // 「使った金額追加時」にのみ、残高が負の場合に取り崩しダイアログを表示する
    // ※ 展開ボタン押下や画面再ビルドでは表示しない
    void checkAndShowWithdrawalDialog() {
      if (isPaidUser && remainingBalance < 0) {
        final savingCard = fixedCosts.firstWhereOrNull((fc) => fc.title == "貯金");
        if (savingCard != null && savingCard.amount > 0) {
          // ダイアログを表示する
          _showToriKuzushiDialog(context, ref, -remainingBalance, savingCard.amount);
        }
      }
    }

    // AppBar 表示
    String remainDisplay;
    if (remainingBalance == 0) {
      remainDisplay = "0円 ※";
    } else if (remainingBalance < 0) {
      remainDisplay = "${remainingBalance.toStringAsFixed(0)}円";
    } else {
      remainDisplay = "${remainingBalance.toStringAsFixed(0)}円";
    }

    Color appBarColor = Colors.white;
    Color remainTextColor = Colors.black;
    if (remainingBalance < 0) {
      appBarColor = Colors.black;
      remainTextColor = Colors.red;
    } else if (isPaidUser) {
      final day = DateTime.now().day;
      final oneThird = remainingBalance / 3.0;
      final threshold = oneThird * 0.2;
      if (day >= 1 && day <= 10 && remainingBalance < threshold && remainingBalance > 0) {
        appBarColor = Colors.yellow.withOpacity(0.5);
      }
      if (day >= 11 && day <= 20 && remainingBalance < threshold && remainingBalance > 0) {
        appBarColor = Colors.yellow.withOpacity(0.5);
      }
      if (day >= 21 && day <= 31 && remainingBalance < threshold && remainingBalance > 0) {
        appBarColor = Colors.yellow.withOpacity(0.5);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          'あと $remainDisplay',
          style: TextStyle(color: remainTextColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 総収入セクション
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
          // 固定費セクション
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
          // 使った金額セクション
          Expanded(child: ExpenseSection(ref: ref)),
          // 入力エリア (支出追加)
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
              // 支出を追加
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
              // 支出追加後、残高再計算＆取り崩しダイアログ表示をチェック
              checkAndShowWithdrawalDialog();
            },
          ),
        ],
      ),
    );
  }

  /// 取り崩しダイアログ（使った金額追加時のみ表示）
  /// savingAmount: 現在の貯金額, shortage: 不足分（正の値）
  void _showToriKuzushiDialog(BuildContext context, WidgetRef ref, double shortage, double savingAmount) {
    final textCtrl = TextEditingController();
    bool errorFlag = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double? inputAmount;
            String? errorMessage;
            return AlertDialog(
              title: const Text("取り崩し"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("貯金額: ${savingAmount.toStringAsFixed(0)}円\n不足: $shortage 円"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MaxValueFormatter(savingAmount)],
                    decoration: InputDecoration(
                      labelText: "取り崩す金額",
                      errorText: errorFlag ? "貯金額を超えています" : null,
                    ),
                    onChanged: (val) {
                      final input = double.tryParse(val);
                      setState(() {
                        inputAmount = input;
                        errorMessage = (input == null || input <= 0 || input > savingAmount)
                            ? "貯金額を超えています"
                            : null;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("キャンセル"),
                ),
                TextButton(
                  onPressed: () {
                    final toriAmount = double.tryParse(textCtrl.text) ?? 0;
                    if (toriAmount <= 0 || toriAmount > savingAmount) {
                      setState(() {
                        errorFlag = true;
                      });
                      return;
                    }
                    Navigator.pop(context);
                    _handleToriKuzushi(context, ref, toriAmount);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 取り崩し処理：
  /// 1) 総収入に "取り崩し" カードを追加（記憶アイコン OFF）
  /// 2) 固定費の「貯金」カードの金額を減らし、記憶アイコンを OFF にする
  void _handleToriKuzushi(BuildContext context, WidgetRef ref, double toriAmount) {
    if (toriAmount <= 0) return;
    final fixedCosts = ref.read(fixedCostViewModelProvider);
    final saving = fixedCosts.firstWhereOrNull((fc) => fc.title == "貯金");
    if (saving == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("貯金がありません。取り崩しはできません。")),
      );
      return;
    }
    final currentSaving = saving.amount;
    if (toriAmount > currentSaving) return;
    final now = DateTime.now();

    // 総収入に取り崩しカードを追加（常に isRemember: false）
    ref.read(incomeViewModelProvider.notifier).addItem(
      Income(
        id: const Uuid().v4(),
        title: "取り崩し",
        amount: toriAmount,
        date: now,
        isRemember: false,
      ),
    );

    // 固定費の貯金カードを更新：金額減少、記憶アイコン OFF
    final newSaving = (currentSaving - toriAmount).clamp(0.0, double.infinity);
    ref.read(fixedCostViewModelProvider.notifier).updateFixedCost(
      saving.copyWith(
        amount: newSaving,
        isRemember: false,
      ),
    );
  }
}

/// カスタム TextInputFormatter: 入力された数字が maxValue を超えた場合、入力前の状態に戻す
class MaxValueFormatter extends TextInputFormatter {
  final double maxValue;
  MaxValueFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final parsed = double.tryParse(newValue.text);
    if (parsed == null) return newValue;
    if (parsed > maxValue) return oldValue;
    return newValue;
  }
}
