class Expense {
  final String title; // 種類
  final double amount; // 金額
  final DateTime date; // 日付

  Expense({
    required this.title,
    required this.amount,
    required this.date,
  });

  // JSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "amount": amount,
      "date": date.toIso8601String(), // ISO 8601形式の文字列に変換
    };
  }

  // JSONから復元
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      title: json['title'],
      amount: (json['amount'] as num).toDouble(), // num型からdouble型に変換
      date: DateTime.parse(json['date']), // ISO 8601形式からDateTime型に変換
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Expense &&
              runtimeType == other.runtimeType &&
              title == other.title &&
              amount == other.amount &&
              date == other.date;

  @override
  int get hashCode => title.hashCode ^ amount.hashCode ^ date.hashCode;
}
