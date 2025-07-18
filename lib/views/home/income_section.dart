import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_income_section.dart';
import 'package:yosan_de_kakeibo/views/widgets/common_section_widget.dart';

class IncomeSection extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const IncomeSection({
    Key? key,
    required this.isExpanded,
    required this.onExpandToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalIncome = ref.watch(totalIncomeProvider); // Riverpodでの状態取得

    return CommonSectionWidget(
      title: '総収入',
      total: totalIncome,
      isExpanded: isExpanded,
      onExpand: onExpandToggle,
      fullScreenWidget: const FullScreenIncomeSection(),
    );
  }
}
