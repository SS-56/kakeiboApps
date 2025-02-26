import 'dart:io';
import 'package:collection/collection.dart'; // firstWhereOrNull 用
import 'package:flutter/material.dart';
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
// 既存の input_area.dart を使う
import 'package:yosan_de_kakeibo/views/widgets/input_area.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // (1) Firebaseアップデート確認 (既存ロジック)
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

    // (2) 残高計算
    final incomes = ref.watch(incomeViewModelProvider);
    final fixedCosts = ref.watch(fixedCostViewModelProvider);
    final expenses = ref.watch(expenseViewModelProvider);

    final totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    final totalFixed = fixedCosts.fold(0.0, (sum, f) => sum + f.amount);
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final remainingBalance = totalIncome - totalFixed - totalSpent;

    // (3) 課金状態
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPaidUser = (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    // (4) AppBar
    String remainText;
    if (remainingBalance == 0) {
      remainText = '0円';
    } else if (remainingBalance < 0) {
      remainText = '${remainingBalance.toStringAsFixed(0)}円';
    } else {
      remainText = '${remainingBalance.toStringAsFixed(0)}円';
    }
    Color barColor = Colors.white;
    Color txtColor = Colors.black;
    if (remainingBalance < 0) {
      barColor = Colors.black;
      txtColor = Colors.red;
    } else {
      // 残額がプラスの場合のみ "xx％" 判定
      // ※ 何を基準に "20%" "10%" を計算するか要注意
      //   - ここでは例として "totalIncome" を基準にする
      final totalIncome = incomes.fold(0.0, (sum, inc) => sum + inc.amount);

      if (totalIncome > 0) {
        final ratio = remainingBalance / totalIncome;
        // ratio < 0.1 => 10％未満 => 薄いピンク
        // ratio < 0.2 => 20％未満 => 薄い黄色
        if (ratio < 0.1) {
          barColor = Colors.pink[100]!;   // 薄いピンク
        } else if (ratio < 0.2) {
          barColor = Colors.yellow[100]!; // 薄い黄色
        }
        // それ以外 => 何もしない(白)
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: barColor,
        title: Text(
          'あと $remainText',
          style: TextStyle(
            color: txtColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 総収入
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

          // 固定費
          CommonSectionWidget(
            title: '固定費',
            total: totalFixed,
            isExpanded: ref.watch(fixedCostsExpandProvider),
            onExpand: () {
              ref.read(fixedCostsExpandProvider.notifier).toggle();
            },
            fullScreenWidget: const FullScreenFixedCostsSection(),
          ),
          const Divider(height: 20, thickness: 2),

          // 使った金額
          Expanded(
            child: ExpenseSection(ref: ref),
          ),

          // 下部: input_area を使った使った金額の追加
          _buildExpenseInputArea(context, ref, remainingBalance, isPaidUser, fixedCosts),
        ],
      ),
    );
  }

  /// input_area で使った金額を追加
  /// 追加後に残高がマイナスなら => 取り崩しDialog => 貯金を減らすのみ
  Widget _buildExpenseInputArea(
      BuildContext context,
      WidgetRef ref,
      double remainingBalance,
      bool isPaidUser,
      List<FixedCost> fixedCosts,
      ) {
    final expensesDate = ref.watch(expensesDateProvider);
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    return InputArea(
      titleController: titleCtrl,
      amountController: amountCtrl,
      selectedDate: expensesDate,
      onDateChange: (newDate) {
        ref.read(expensesDateProvider.notifier).state = newDate;
      },
      onAdd: () {
        final title = titleCtrl.text.trim();
        final amount = double.tryParse(amountCtrl.text);
        if (title.isEmpty || amount == null || amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('すべての項目を入力してください')),
          );
          return;
        }

        // 使った金額を追加
        ref.read(expenseViewModelProvider.notifier).addItem(
          Expense(
            id: const Uuid().v4(),
            title: title,
            amount: amount,
            date: expensesDate,
          ),
        );
        titleCtrl.clear();
        amountCtrl.clear();

        // 追加後 => 残高がマイナスなら取り崩し
        final newRemain = remainingBalance - amount;
        if (isPaidUser && newRemain < 0) {
          final savingCard = fixedCosts.firstWhereOrNull((fc) => fc.title == '貯金');
          if (savingCard != null && savingCard.amount > 0) {
            final shortage = -(newRemain);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showTorikuzushiDialogAfterAdd(context, ref, shortage, savingCard.amount);
            });
          }
        }
      },
    );
  }

  /// 使った金額追加後 => 取り崩しDialog
  void _showTorikuzushiDialogAfterAdd(
      BuildContext context,
      WidgetRef ref,
      double shortage,
      double savingAmount,
      ) {
    final textCtrl = TextEditingController();
    bool errorFlag = false;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('取り崩し'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('貯金: ${savingAmount.toStringAsFixed(0)}円\n不足: ${shortage.toStringAsFixed(0)}円'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: textCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '取り崩し金額',
                      errorText: errorFlag ? '貯金を超えています' : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () {
                    final val = double.tryParse(textCtrl.text) ?? 0;
                    if (val <= 0 || val > savingAmount) {
                      setState(() => errorFlag = true);
                      return;
                    }
                    Navigator.pop(dialogCtx);
                    // 取り崩し処理 => 総収入に追加しないで貯金を減らすのみ
                    _handleTorikuzushi(ref, context, val);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 取り崩し処理 => 貯金Cardだけを減らす (総収入に加算しない)
  void _handleTorikuzushi(WidgetRef ref, BuildContext context, double toriAmount) {
    final fixedCosts = ref.read(fixedCostViewModelProvider);
    final saving = fixedCosts.firstWhereOrNull((fc) => fc.title == '貯金');
    if (saving == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('貯金がありません。取り崩しできません。')),
      );
      return;
    }
    if (toriAmount > saving.amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('貯金額 (${saving.amount}) を超えています。')),
      );
      return;
    }

    // ここで総収入に "取り崩し" を追加していたのを削除:
    // ref.read(incomeViewModelProvider.notifier).addItem(...); // 削除

    // 貯金を減らすだけ
    final newSaving = (saving.amount - toriAmount).clamp(0.0, double.infinity);
    ref.read(fixedCostViewModelProvider.notifier).updateFixedCost(
      saving.copyWith(
        amount: newSaving,
        isRemember: newSaving > 0,
      ),
    );
  }
}
