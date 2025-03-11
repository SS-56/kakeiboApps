import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/services/firebase_service.dart';

class FirebaseRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 課金プラン取得（リトライ付き）
  Future<String?> getSubscriptionPlanWithRetry(String userId) async {
    int retryCount = 0;
    const maxRetries = 3;
    while (retryCount < maxRetries) {
      try {
        final data = await _firebaseService.getDocument('subscriptions', userId);
        return data?['plan'] as String?;
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
  Future<void> saveFixedCost(FixedCost fixedCost) => _firebaseService.saveFixedCost(fixedCost);

  Future<void> saveIncomeCard(Income income) async {
    await _firestore.collection('saved_income').doc(income.id).set(income.toJson());
  }

  Future<List<Income>> getSavedIncomeCards() async {
    final snapshot = await _firestore.collection('saved_income').get();
    return snapshot.docs.map((doc) => Income.fromJson(doc.data())).toList();
  }

  Future<void> saveFixedCostCard(FixedCost cost) async {
    await _firestore.collection('saved_fixed_costs').doc(cost.id).set(cost.toJson());
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
      'incomes'   : incomes.map((e) => e.toJson()).toList(),
      'fixedCosts': fixedCosts.map((e) => e.toJson()).toList(),
      'expenses'  : expenses.map((e) => e.toJson()).toList(),
      'timestamp' : FieldValue.serverTimestamp(),
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
      final userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);
      return userCredential;
    } catch (e) {
      print("Appleでの認証エラー: $e");
      rethrow;
    }
  }
}

final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});
