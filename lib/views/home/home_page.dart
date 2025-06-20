import 'dart:io';
import 'package:collection/collection.dart'; // firstWhereOrNull 用
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:yosan_de_kakeibo/handlers/monthly_data_handler.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
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
// ★ 新規に作成する読み取り専用のホーム画面過去データ用ページ
import 'package:yosan_de_kakeibo/views/home/home_history_page.dart';

import '../../services/shared_preferences_service.dart';
import '../../utils/date_utils.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  // ▼ 修正：設定画面で更新される startDayProvider を使って残り日数を計算する
  Future<int> _calculateRemainingDays(WidgetRef ref) async {
    final now = DateTime.now();
    // startDayProvider は SettingsPage で更新される整数（日付の「日」部分）
    final startDay = ref.watch(startDayProvider);
    // 今月の開始日として算出（例：現在月の17日）
    final startDate = DateTime(now.year, now.month, startDay);
    // 次の締め日（1ヶ月後）を計算
    DateTime nextCycle = _addOneMonth(startDate);
    // 今よりも未来になるまで1ヶ月ずつ足す
    while (!nextCycle.isAfter(now)) {
      nextCycle = _addOneMonth(nextCycle);
    }
    return nextCycle.difference(now).inDays;
  }

  // 1ヶ月先を計算するヘルパー関数（自動で月末調整される）
  DateTime _addOneMonth(DateTime base) {
    return DateTime(base.year, base.month + 1, base.day);
  }

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
    final isPaidUser =
    (subscriptionStatus == 'basic' || subscriptionStatus == 'premium');

    // (4) AppBar 用残高表示設定
    String remainText;
    if (remainingBalance == 0) {
      remainText = '¥0';
    } else if (remainingBalance < 0) {
      remainText = '¥${remainingBalance.toStringAsFixed(0)}';
    } else {
      remainText = '¥${remainingBalance.toStringAsFixed(0)}';
    }
    Color? barColor = Colors.cyan;
    Color txtColor = Colors.white;
    if (remainingBalance < 0) {
      barColor = Colors.black;
      txtColor = Colors.red;
    } else {
      final totalInc = incomes.fold(0.0, (sum, inc) => sum + inc.amount);
      if (totalInc > 0) {
        final ratio = remainingBalance / totalInc;
        if (ratio < 0.1) {
          barColor = Colors.pink[100]!;
          txtColor = Colors.black;
        } else if (ratio < 0.2) {
          barColor = Colors.yellow[100]!;
          txtColor = Colors.black;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: barColor,
        title: FutureBuilder<int>(
          future: _calculateRemainingDays(ref),
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('読み込み中...');
            } else if (snapshot.hasError) {
              return Text('エラー: ${snapshot.error}');
            } else {
              final remainingDays = snapshot.data ?? 0;
              return Text(
                'あと ${remainingDays}日で $remainText',
                style: TextStyle(
                  color: txtColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              );
            }
          },
        ),
        centerTitle: true,
        // ★ 課金ユーザーのみ、leadingに <ボタンを追加
        leading: isPaidUser
            ? IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.black,
            size: 32,
          ),
          onPressed: () async {
            await finalizeMonth(ref);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (ctx, anim, secAnim) => const HomeHistoryPage(),
                transitionsBuilder: (ctx, anim, secAnim, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  final tween = Tween(begin: begin, end: end);
                  final curve = Curves.easeInOut;
                  return SlideTransition(
                    position: tween.animate(
                        CurvedAnimation(parent: anim, curve: curve)),
                    child: child,
                  );
                },
              ),
            );
          },
        )
            : null,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // 総収入
            CommonSectionWidget(
              title: '収入',
              total: totalIncome,
              isExpanded: ref.watch(incomeExpandProvider),
              onExpand: () {
                ref.read(incomeExpandProvider.notifier).toggle();
              },
              fullScreenWidget: const FullScreenIncomeSection(),
            ),
            const Divider(
              height: 20,
              thickness: 2,
              color: Colors.cyan,
            ),
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
            const Divider(
              height: 20,
              thickness: 2,
              color: Colors.cyan,
            ),
            // 使った金額
            Expanded(
              child: ExpenseSection(ref: ref),
            ),
            // 下部: input_area を使った使った金額の追加
            _buildExpenseInputArea(context, ref, remainingBalance, isPaidUser, fixedCosts),
          ],
        ),
      ),
    );
  }

  // 以下のコードは既存のまま残し、削除しない
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
        if (title.isEmpty || amount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('すべての項目を入力してください')),
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
        titleCtrl.clear();
        amountCtrl.clear();
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
    final newSaving = (saving.amount - toriAmount).clamp(0.0, double.infinity);
    ref.read(fixedCostViewModelProvider.notifier).updateFixedCost(
      saving.copyWith(
        amount: newSaving,
        isRemember: newSaving > 0,
      ),
    );
  }

  // 既存の startDay 更新処理はそのまま。設定画面で更新された startDayProvider を利用するため、
  // SharedPreferences への保存とプロバイダーのリフレッシュを実施します。
  void _applyNewStartDay(WidgetRef ref, int newDay) {
    ref.read(startDayProvider.notifier).setStartDay(newDay);
    print("開始日が更新されました: $newDay 日");

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, newDay);

    // 新しい開始日を SharedPreferences に保存
    saveStartDate(startDate);
    // プロバイダーをリフレッシュして最新の値を反映
    ref.refresh(startDateProvider);

    final endDate = calculateEndDate(startDate);
    ref.read(expenseViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    ref.read(fixedCostViewModelProvider.notifier).filterByDateRange(startDate, endDate);
    ref.read(incomeViewModelProvider.notifier).filterByDateRange(startDate, endDate);

    final budgetPeriodMessage =
        "${startDate.month}月${startDate.day}日から${endDate.month}月${endDate.day}日までを管理します";
    ref.read(budgetPeriodProvider.notifier).state = budgetPeriodMessage;

    print("管理期間メッセージ: $budgetPeriodMessage");
  }

  void _showEarlierDateConfirmDialog(
      BuildContext context,
      WidgetRef ref,
      int newDay,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("開始日を変更します"),
          content: const Text(
            "この日付を選択すると、開始日より前のデータが消去されます。\nよろしいですか？",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800]),),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _updateStartDay(ref, newDay);
              },
              child: Text("OK", style: TextStyle(color: Colors.cyan[800]),),
            ),
          ],
        );
      },
    );
  }

  void _updateStartDay(WidgetRef ref, int newDay) {
    final oldDay = ref.read(startDayProvider);
    print("開始日が更新されます: old=$oldDay → new=$newDay");
    if (newDay < oldDay) {
      _showConfirmEarlierStartDay(ref, newDay);
    } else {
      _applyNewStartDay(ref, newDay);
    }
  }

  void _showConfirmEarlierStartDay(WidgetRef ref, int newDay) {
    showDialog(
      context: ref.context,
      builder: (_) => AlertDialog(
        title: const Text("開始日より前の日付を選択しました"),
        content: const Text(
          "この日付を選ぶと、開始日より前のカードが消去される可能性があります。\nよろしいですか？",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ref.context),
            child: Text("キャンセル", style: TextStyle(color: Colors.cyan[800]),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ref.context);
              _applyNewStartDay(ref, newDay);
            },
            child: Text("OK", style: TextStyle(color: Colors.cyan[800]),),
          ),
        ],
      ),
    );
  }
}
