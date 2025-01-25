class Income {
  final String? id;
  final DateTime date;
  final String title;
  final double amount;

  Income({
    this.id,
    required this.date,
    required this.title,
    required this.amount,
  });

  Map<String, dynamic> toJson({bool includeId = false}) {
    final data = {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
    };

    if (includeId && id != null) {
      data['id'] = id!;
    }

    return data;
  }

  static Income fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String?,
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date'] as String),
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
