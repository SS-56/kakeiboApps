// models/medal.dart

enum MedalType {
  none,
  bronze,
  silver,
  gold,
}

class Medal {
  final MedalType type;         // bronze, silver, gold, none
  final String description;     // メダルの説明 (ex: "貯金を減らさずに～" など)
  final DateTime awardedDate;   // 獲得日

  Medal({
    required this.type,
    required this.description,
    required this.awardedDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),     // "MedalType.bronze" 等
      'description': description,
      'awardedDate': awardedDate.toIso8601String(),
    };
  }

  static Medal fromJson(Map<String, dynamic> json) {
    // json["type"] は "MedalType.bronze" のように保存されている想定
    // 文字列 => enum 変換
    final String typeString = json['type'] as String;
    final MedalType parsedType = _stringToMedalType(typeString);

    return Medal(
      type: parsedType,
      description: json['description'],
      awardedDate: DateTime.parse(json['awardedDate']),
    );
  }

  /// 文字列から enum へ変換
  /// 例: "MedalType.bronze" -> MedalType.bronze
  static MedalType _stringToMedalType(String enumString) {
    // 例えば "MedalType.bronze" なら最後の ".bronze" 部分を切り出す
    final segments = enumString.split('.');
    if (segments.length == 2) {
      final key = segments[1];
      switch (key) {
        case 'none':
          return MedalType.none;
        case 'bronze':
          return MedalType.bronze;
        case 'silver':
          return MedalType.silver;
        case 'gold':
          return MedalType.gold;
      }
    }
    // 想定外 => none 扱い
    return MedalType.none;
  }
}
