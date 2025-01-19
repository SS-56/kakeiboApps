import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  // データを保存
  Future<void> saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      throw Exception("Unsupported data type");
    }
  }

  // リストデータを保存
  Future<void> saveList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final jsonString = jsonEncode(value);
      await prefs.setString(key, jsonString);
    } catch (e) {
      throw Exception("Failed to encode JSON: $e");
    }
  }

  // リストデータを取得
  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final jsonString = prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) {
        return []; // 空のリストを返す
      }
      final List<dynamic> jsonData = jsonDecode(jsonString);
      return List<Map<String, dynamic>>.from(jsonData);
    } catch (e) {
      print("Error decoding JSON for key $key: $e");
      return []; // デフォルト値として空リストを返す
    }
  }

  // データを削除
  Future<void> deleteData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // 全データを削除
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
