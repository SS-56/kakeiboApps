import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_fixed_costs_section.dart';
import 'package:yosan_de_kakeibo/views/widgets/common_section_widget.dart';

class FixedCostsSection extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const FixedCostsSection({
    Key? key,
    required this.isExpanded,
    required this.onExpandToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalFixedCost = ref.watch(totalFixedCostProvider); // Riverpodでの状態取得

    return CommonSectionWidget(
      title: '固定費',
      total: totalFixedCost,
      isExpanded: isExpanded,
      onExpand: onExpandToggle,
      fullScreenWidget: const FullScreenFixedCostsSection(),
    );
  }
}
