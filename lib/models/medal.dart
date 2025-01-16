class Medal {
  final String type; // 'bronze', 'silver', 'gold'
  final String description; // メダルの説明
  final DateTime awardedDate; // 獲得日

  Medal({
    required this.type,
    required this.description,
    required this.awardedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'awardedDate': awardedDate.toIso8601String(),
    };
  }

  static Medal fromJson(Map<String, dynamic> json) {
    return Medal(
      type: json['type'],
      description: json['description'],
      awardedDate: DateTime.parse(json['awardedDate']),
    );
  }
}
