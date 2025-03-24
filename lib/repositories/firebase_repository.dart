import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/services/firebase_service.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

class FirebaseRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 課金プラン取得（リトライ付き）
  Future<String?> getSubscriptionPlanWithRetry(String userId) async {
    int retryCount = 0;
    const maxRetries = 3;
    while (retryCount < maxRetries) {
      try {
        final data = await _firebaseService.getDocument('users', userId); //修正
        return data?['planId'] as String?; //修正
      } catch (e) {
        retryCount++;
        print("リトライ: $retryCount / $maxRetries");
        if (retryCount >= maxRetries) {
          throw Exception("課金プランの取得に失敗しました: $e");
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    return null;
  }

  /// ====== 既存のメソッド ======
  Future<void> saveExpense(Expense expense) => _firebaseService.saveExpense(expense);
  Future<void> saveIncome(Income income) => _firebaseService.saveIncome(income);
  Future<void> saveFixedCost(FixedCost fixedCost) =>
      _firebaseService.saveFixedCost(fixedCost);

  Future<void> saveIncomeCard(Income income) async {
    await _firestore
        .collection('saved_income')
        .doc(income.id)
        .set(income.toJson());
  }

  Future<List<Income>> getSavedIncomeCards() async {
    final snapshot = await _firestore.collection('saved_income').get();
    return snapshot.docs.map((doc) => Income.fromJson(doc.data())).toList();
  }

  Future<void> saveFixedCostCard(FixedCost cost) async {
    await _firestore
        .collection('saved_fixed_costs')
        .doc(cost.id)
        .set(cost.toJson());
  }

  Future<List<FixedCost>> getSavedFixedCostCards() async {
    final snapshot = await _firestore.collection('saved_fixed_costs').get();
    return snapshot.docs.map((doc) => FixedCost.fromJson(doc.data())).toList();
  }

  /// 月次まとめ保存
  Future<void> saveMonthlyData({
    required String uid,
    required String yyyyMM,
    required List<Income> incomes,
    required List<FixedCost> fixedCosts,
    required List<Expense> expenses,
    Map<String, dynamic>? metadata,
  }) async {
    final docRef = _firestore
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .doc(yyyyMM);

    final data = {
      'incomes': incomes.map((e) => e.toJson()).toList(),
      'fixedCosts': fixedCosts.map((e) => e.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (metadata != null) {
      data['metadata'] = metadata;
    }
    await docRef.set(data);
  }

  Future<Map<String, dynamic>?> getMonthlyData({
    required String uid,
    required String yyyyMM,
  }) async {
    final docSnap = await _firestore
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .doc(yyyyMM)
        .get();
    if (!docSnap.exists) return null;
    return docSnap.data();
  }

  Future<void> pruneOldMonthlyData({required String uid}) async {
    // 必要に応じて実装
  }

  /// ホーム画面の過去データ: 24件取得
  Future<List<Map<String, dynamic>>> loadHomeHistory(String uid) async {
    final snap = await _firestore
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .orderBy('timestamp', descending: true)
        .limit(24)
        .get();

    if (snap.docs.isEmpty) {
      return [];
    }
    final List<Map<String, dynamic>> result = [];
    for (final doc in snap.docs) {
      final data = doc.data();
      data['docId'] = doc.id;
      result.add(data);
    }
    return result;
  }

  /// マイページの過去データ: 24件取得
  Future<List<Map<String, dynamic>>> loadMyPageHistory(String uid) async {
    final snap = await _firestore
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .orderBy('timestamp', descending: true)
        .limit(24)
        .get();

    if (snap.docs.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> result = [];
    for (final doc in snap.docs) {
      final data = doc.data();
      data['docId'] = doc.id;
      result.add(data);
    }
    return result;
  }

  Future<UserCredential?> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithProvider(appleProvider);
      return userCredential;
    } catch (e) {
      print("Appleでの認証エラー: $e");
      rethrow;
    }
  }

  // ====== 追加されたメソッド ======
  Future<void> markUserAsSubscribed(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'subscription_plan': planId,
        'subscription_date': DateTime.now(),
      });
    } catch (e) {
      // エラーハンドリング
      print('FirebaseRepository.markUserAsSubscribed error: $e');
      throw Exception('Failed to update user subscription status.');
    }
  }

  Future<void> markUserAsUnsubscribed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    // subscription_plan フィールドを null に設定 (または削除)
    await _firestore.collection('users').doc(user.uid).set(
      {'subscription_plan': null},
      SetOptions(merge: true),
    );
    // または
    // await _firestore.collection('users').doc(user.uid).update({
    //   'subscription_plan': FieldValue.delete(),
    // });
  }

  // サブスクリプションプランを取得
  Future<String?> getSubscriptionPlan(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      // subscription_plan フィールドが存在し、その値が文字列であることを確認
      final data = doc.data();
      if (data != null && data.containsKey('subscription_plan')) {
        final plan = data['subscription_plan'];
        if (plan is String) {
          return plan;
        } else if (plan == null) {
          return null; // subscription_plan が null の場合
        } else {
          print('Error: subscription_plan is not a String');
          return null; // 型が不正な場合は null を返す (または例外をスロー)
        }
      }
    }
    return null; // ドキュメントが存在しない、または subscription_plan フィールドがない
  }

  Future<String?> fetchSubscriptionPlan() async {
    final user = _auth.currentUser;
    if (user == null) {
      // ログインしていない場合は null を返す (または適切なエラー処理)
      return null;
    }

    try {
      final docSnapshot =
      await _firestore.collection('users').doc(user.uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['subscription_plan'] as String?;
      } else {
        // ドキュメントが存在しない場合は null を返す (または適切なエラー処理)
        return null;
      }
    } catch (e) {
      // エラー処理 (ログ出力、エラーを返すなど)
      print('Error fetching subscription plan: $e');
      return null; // または、エラーを示す特別な値を返す
    }
  }

  Future<void> recordRestoredPurchase(PurchaseDetails restoredPurchase) async {
    return _firebaseService.recordRestoredPurchase(restoredPurchase);
  }
}

final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});