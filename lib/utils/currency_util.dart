import 'package:intl/intl.dart';

/// 金額を指定された通貨コードでフォーマットする関数
/// - 日本円 (JPY) の場合は小数点を使わず、"￥" をシンボルとして表示します。
/// - 外貨の場合は小数点以下2桁で表示します。
String formatCurrency(double amount, {String currencyCode = 'JPY'}) {
  if (currencyCode == 'JPY') {
    // 日本円の場合：小数点なし、シンボルを "￥" として設定
    final formatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: '￥',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  } else {
    // 外貨の場合：小数点以下2桁、シンボルは各通貨のルールに従う
    final formatter = NumberFormat.currency(
      locale: 'en_US', // 必要に応じてユーザーのロケールに合わせる
      name: currencyCode,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
