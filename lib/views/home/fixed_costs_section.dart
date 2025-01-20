import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/providers/page_providers.dart';
import 'package:yosan_de_kakeibo/views/home/full_screen_fixed_costs_section.dart';

class FixedCostSection extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final double totalFixedCosts; // このプロパティを追加

  const FixedCostSection({
    super.key,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.totalFixedCosts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalFixedCosts = ref.watch(totalFixedCostProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onExpandToggle,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '固定費',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            SizedBox(
              height: MediaQuery.of(context).size.height / 20,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${totalFixedCosts.toStringAsFixed(0)} 円',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FullScreenFixedCostsSection()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
