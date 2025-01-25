import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_status.dart';

final userStatusProvider =
StateNotifierProvider<UserStatusViewModel, UserStatus>((ref) {
  return UserStatusViewModel();
});

class UserStatusViewModel extends StateNotifier<UserStatus> {
  UserStatusViewModel() : super(UserStatus.free()) {
    _loadUserStatus(); // 起動時に課金状態をロード
  }

  /// ユーザーの課金状態をロード
  Future<void> _loadUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final plan = prefs.getString('subscription_plan') ?? "free";

    if (plan == "basic") {
      state = UserStatus.basic();
    } else if (plan == "premium") {
      state = UserStatus.premium();
    } else {
      state = UserStatus.free();
    }
  }

  /// ユーザーの課金状態を保存
  Future<void> saveStatus(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan);

    state = _mapPlanToStatus(plan);
  }

  /// 課金プランをUserStatusに変換
  UserStatus _mapPlanToStatus(String plan) {
    if (plan == "basic") {
      return UserStatus.basic();
    } else if (plan == "premium") {
      return UserStatus.premium();
    } else {
      return UserStatus.free();
    }
  }



  /// ユーザーの課金状態を保存
  Future<void> setUserStatus(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan);

    if (plan == "basic") {
      state = UserStatus.basic();
    } else if (plan == "premium") {
      state = UserStatus.premium();
    } else {
      state = UserStatus.free();
    }
  }



  /// ログアウト処理
  Future<void> logout() async {
    await setUserStatus("free");
  }
}
