import 'package:flutter/material.dart';

class CommonSectionWidget extends StatelessWidget {
  final String title;
  final double total;
  final bool isExpanded;
  final VoidCallback onExpand;
  final Widget fullScreenWidget;

  const CommonSectionWidget({
    super.key,
    required this.title,
    required this.total,
    required this.isExpanded,
    required this.onExpand,
    required this.fullScreenWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onExpand,
            child: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
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
                      '${total.toStringAsFixed(0)} 円',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.blue),
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
