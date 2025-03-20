import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';

/// メダル情報の保存・取得インターフェイス
abstract class MedalRepository {
  Future<List<Medal>> getMedals();
  Future<void> saveMedals(List<Medal> medals);
}

/// 実装: SharedPreferences
class MedalRepositoryImpl implements MedalRepository {
  static const _medalsKey = "saved_medals_list";

  @override
  Future<List<Medal>> getMedals() async {
    final sp = await SharedPreferences.getInstance();
    final jsonString = sp.getString(_medalsKey);
    if (jsonString == null) {
      return [];
    }
    final List decoded = jsonDecode(jsonString) as List;
    return decoded.map((m) => Medal.fromJson(m as Map<String,dynamic>)).toList();
  }

  @override
  Future<void> saveMedals(List<Medal> medals) async {
    final sp = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      medals.map((m) => m.toJson()).toList(),
    );
    await sp.setString(_medalsKey, encoded);
  }
}

// Provider
final medalRepositoryProvider = Provider<MedalRepository>((ref) {
  return MedalRepositoryImpl();
});
