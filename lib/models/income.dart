class Income {
  final String? id;
  final DateTime date;
  final String title;
  final double amount;

  String? memo;
  bool isRemember;

  Income({
    this.id,
    required this.date,
    required this.title,
    required this.amount,

    this.memo,
    this.isRemember = false,
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

   Income copyWith({
     String? title,
     double? amount,
     DateTime? date,
     String? memo,
     bool? isRemember,
   }) {
  return Income(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      isRemember: isRemember ?? this.isRemember,
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

  @override
  int get hashCode => Object.hash(date, title, amount);
}
