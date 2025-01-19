import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  // データを保存
  Future<void> saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
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
    } catch (e) {
      print("Error saving data for key $key: $e");
      rethrow;
    }
  }

  // リストデータを保存
  Future<void> saveList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final jsonString = jsonEncode(value);
      await prefs.setString(key, jsonString);
    } catch (e) {
      print("Error saving list for key $key: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final jsonString = prefs.getString(key);
      print('Raw JSON for $key: $jsonString'); // ログ追加

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonData = jsonDecode(jsonString);
      return List<Map<String, dynamic>>.from(jsonData);
    } catch (e) {
      print("Error decoding JSON for key $key: $e");
      return [];
    }
  }

  // データを削除
  Future<void> deleteData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.remove(key);
    } catch (e) {
      print("Error deleting data for key $key: $e");
      rethrow;
    }
  }

  // 全データを削除
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.clear();
    } catch (e) {
      print("Error clearing all data: $e");
      rethrow;
    }
  }
}
Future<void> debugSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final allKeys = prefs.getKeys();
  print('SharedPreferences Debug Start');
  for (var key in allKeys) {
    print('$key: ${prefs.get(key)}');
  }
  print('SharedPreferences Debug End');
}
