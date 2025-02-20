import 'package:flutter/material.dart';

class Income {
  final String id;
  final DateTime date;
  final String title;
  final double amount;
  final IconData? icon; // アイコンを追加

  String? memo;
  bool isRemember;
  final int? dayOfMonth;

  Income({
    required this.id,
    required this.date,
    required this.title,
    required this.amount,
    this.icon, // アイコンをオプションで受け取る

    this.memo,
    this.isRemember = false,
    this.dayOfMonth,
  });

  @override
  String toString() {
    return 'Income(title: $title, amount: $amount, date: $date)';
  }

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
      id: json['id'] as String,
      title: json['title'],
      amount: json['amount'],
      date: DateTime.parse(json['date'] as String),
    );
  }

  Income copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? memo,
    bool? isRemember,
    int? dayOfMonth,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      isRemember: isRemember ?? this.isRemember,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    );
  }
}