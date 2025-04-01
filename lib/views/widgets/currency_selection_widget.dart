import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../view_models/currency_notifier.dart';

class CurrencySelectionWidget extends ConsumerWidget {
  const CurrencySelectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyProvider);
    return DropdownButton<String>(
      value: currentCurrency,
      items: const [
        DropdownMenuItem(value: 'USD', child: Text('ドル')),
        DropdownMenuItem(value: 'EUR', child: Text('ユーロ')),
        DropdownMenuItem(value: 'GBP', child: Text('ポンド')),
        DropdownMenuItem(value: 'AUD', child: Text('オーストラリアドル')),
        DropdownMenuItem(value: 'SGD', child: Text('シンガポールドル')),
      ],
      onChanged: (value) {
        if (value != null) {
          ref.read(currencyProvider.notifier).state = value;
        }
      },
    );
  }
}
