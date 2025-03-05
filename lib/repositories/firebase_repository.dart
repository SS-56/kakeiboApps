import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/services/firebase_service.dart';

class FirebaseRepository {
  // 既存のフィールド・コンストラクタ
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ***課金プランの取得（リトライ付き）***
  Future<String?> getSubscriptionPlanWithRetry(String userId) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Firestoreから課金プランを取得
        return await _firebaseService
            .getDocument('subscriptions', userId)
            .then((data) {
          return data?['plan'] as String?;
        });
      } catch (e) {
        retryCount++;
        print("リトライ: $retryCount / $maxRetries");

        if (retryCount >= maxRetries) {
          throw Exception("課金プランの取得に失敗しました: $e");
        }
        await Future.delayed(const Duration(seconds: 2)); // リトライ前に遅延
      }
    }
    return null; // 到達することはないが、安全のため
  }

  /// ====== 既存のメソッド ======
  Future<void> saveExpense(Expense expense) =>
      _firebaseService.saveExpense(expense);

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

  /// ====== 既存: 月次まとめ保存 ======
  Future<void> saveMonthlyData({
    required String uid,
    required String yyyyMM,
    required List<Income> incomes,
    required List<FixedCost> fixedCosts,
    required List<Expense> expenses,
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
    // 例: monthly_dataをtimestamp昇順で取得し、25件以上なら古い分を削除 etc.
    // ...
  }

  // --------------------------------------------------------------------------------
  // ★ 新規追加: ホーム画面の過去データを取得する例
  //  -> monthly_data コレクションから timestamp 降順で1件のみ取得
  // --------------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> loadHomeHistory(String uid) async {
    // ここで monthly_data の最新ドキュメントを取得する例
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
      data['docId'] = doc.id; // doc.id = 'yyyyMM'
      result.add(data);
    }
    return result; // => HomeHistoryPage で List<Map<String,dynamic>> として使用
  }

  // --------------------------------------------------------------------------------
  // ★ 新規追加: マイページの過去データを取得する例
  //  -> 同じ monthly_data から浪費や貯金額を取り出す場合
  // --------------------------------------------------------------------------------
  Future<Map<String, dynamic>?> loadMyPageHistory(String uid) async {
    // 例: 同様に 1件だけ取得
    final snap = await _firestore
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return null;
    }
    // 1件だけ返す場合
    return snap.docs.first.data();
  }
}

final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  return FirebaseRepository();
});
