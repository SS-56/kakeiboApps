class Expense {
  final String? id;
  final String title; // 種類
  final double amount; // 金額
  final DateTime date; // 日付

  String? memo;
  bool isWaste;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.date,

    this.memo,
    this.isWaste = false,
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

  // JSONから復元
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      title: json['title'],
      amount: (json['amount'] as num).toDouble(), // num型からdouble型に変換
      date: DateTime.parse(json['date'] as String),
    );
  }

   Expense copyWith({
     String? title,
     double? amount,
     DateTime? date,
     String? memo,
     bool? isWaste,
   }) {
    return Expense(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      isWaste: isWaste ?? this.isWaste,
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
