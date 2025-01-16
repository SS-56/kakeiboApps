class Income {
  final DateTime date;
  final String title;
  final double amount;

  Income({
    required this.date,
    required this.title,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'title': title,
      'amount': amount,
    };
  }

  static Income fromJson(Map<String, dynamic> json) {
    return Income(
      date: DateTime.parse(json['date']),
      title: json['title'],
      amount: json['amount'],
    );
  }
  // 重複を判定するための比較演算子とハッシュコード
  @override
  bool operator ==(Object other) {
    return other is Income &&
        other.date == date &&
        other.title == title &&
        other.amount == amount;
  }

  // @override
  // int get hashCode => date.hashCode ^ title.hashCode ^ amount.hashCode;

  @override
  int get hashCode => Object.hash(date, title, amount);
}
