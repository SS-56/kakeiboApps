// File: test/utils/fake_firebase_repository.dart
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class FakeFirebaseRepository implements FirebaseRepository {
  // 内部で保存するデータ（シンプルなメモリ上の保存）
  List<Medal> _medals = [];

  @override
  Future<String?> getSubscriptionPlanWithRetry(String userId) async => null;

  @override
  Future<void> saveExpense(Expense expense) async {}

  @override
  Future<void> saveIncome(Income income) async {}

  @override
  Future<void> saveFixedCost(FixedCost fixedCost) async {}

  @override
  Future<void> saveIncomeCard(Income income) async {}

  @override
  Future<List<Income>> getSavedIncomeCards() async => [];

  @override
  Future<void> saveFixedCostCard(FixedCost cost) async {}

  @override
  Future<List<FixedCost>> getSavedFixedCostCards() async => [];

  @override
  Future<void> saveMonthlyData({
    required String uid,
    required String yyyyMM,
    required List<Income> incomes,
    required List<FixedCost> fixedCosts,
    required List<Expense> expenses,
    Map<String, dynamic>? metadata,
  }) async {
    // テスト用に何もしない
  }

  @override
  Future<Map<String, dynamic>?> getMonthlyData({
    required String uid,
    required String yyyyMM,
  }) async => null;

  @override
  Future<void> pruneOldMonthlyData({required String uid}) async {}

  @override
  Future<List<Map<String, dynamic>>> loadHomeHistory(String uid) async => [];

  @override
  Future<List<Map<String, dynamic>>> loadMyPageHistory(String uid) async => [];

  @override
  Future<UserCredential?> signInWithApple() async => null;

  @override
  Future<void> signInAnonymouslyIfNeeded() async {}

  @override
  Future<void> markUserAsSubscribed(String planId) async {}

  @override
  Future<void> markUserAsUnsubscribed() async {}

  @override
  Future<String?> getSubscriptionPlan(String userId) async => null;

  @override
  Future<String?> fetchSubscriptionPlan() async => null;

  @override
  Future<void> recordRestoredPurchase(PurchaseDetails restoredPurchase) async {}
}
