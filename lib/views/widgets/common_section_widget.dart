import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommonSectionWidget extends ConsumerWidget {
  final String title;
  final double total;
  final bool isExpanded;
  final VoidCallback onExpand;
  final Widget fullScreenWidget;

  const CommonSectionWidget({
    Key? key,
    required this.title,
    required this.total,
    required this.isExpanded,
    required this.onExpand,
    required this.fullScreenWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onExpand,
            child: Container(
              // パネルの色指定
              color: Colors.grey[10],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,color: Colors.cyan,
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
                      '${total.toStringAsFixed(0)} 円',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => fullScreenWidget),
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
