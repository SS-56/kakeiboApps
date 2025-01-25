import 'dart:async';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';
import 'package:yosan_de_kakeibo/services/firebase_service.dart';

class FirebaseRepository {
  final FirebaseService _firebaseService = FirebaseService();

  /// ***課金プランの取得（リトライ付き）***
  Future<String?> getSubscriptionPlanWithRetry(String userId) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Firestoreから課金プランを取得
        return await _firebaseService.getDocument('subscriptions', userId).then((data) {
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
  Future<void> saveExpense(Expense expense) =>
      _firebaseService.saveExpense(expense);

  Future<void> saveIncome(Income income) =>
      _firebaseService.saveIncome(income);

  Future<void> saveFixedCost(FixedCost fixedCost) =>
      _firebaseService.saveFixedCost(fixedCost);
}
