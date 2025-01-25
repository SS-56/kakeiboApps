import 'package:flutter/material.dart';

class FixedCost {
  final String? id;
  final String title; // 修正：nameをtitleに変更
  final double amount;
  final DateTime date; // 修正：dateフィールドを追加
  final IconData? icon; // アイコンを追加

  FixedCost({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.icon, // アイコンをオプションで受け取る
  });

  @override
  String toString() {
    return 'FixedCost(title: $title, amount: $amount, date: $date)';
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

  static FixedCost fromJson(Map<String, dynamic> json) {
    return FixedCost(
      id: json['id'] as String?,
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FixedCost &&
        other.date == date &&
        other.title == title &&
        other.amount == amount;
  }

  @override
  int get hashCode => date.hashCode ^ title.hashCode ^ amount.hashCode;
}
