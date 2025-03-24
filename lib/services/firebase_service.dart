import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yosan_de_kakeibo/models/expense.dart';
import 'package:yosan_de_kakeibo/models/fixed_cost.dart';
import 'package:yosan_de_kakeibo/models/income.dart';


class FirebaseService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ***Remote Configの初期化とフェッチ***
  Future<void> initialize() async {
    try {
      print("Firebase Remote Config 初期化開始...");
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 10),
      ));

      // fetchAndActivate を復元
      final success = await _remoteConfig.fetchAndActivate();
      print("フェッチ成功: $success");
      if (!success) {
        print("フェッチに失敗しました。キャッシュ値またはデフォルト値を使用します。");
      }
    } catch (e) {
      print("Remote Config 初期化エラー: $e");
      throw Exception("Remote Configの初期化に失敗しました。通信環境を確認してください。");
    }
  }

  /// ***最新バージョンの取得***
  String getLatestVersion() {
    final version = _remoteConfig.getString('latest_app_version');
    print("取得した最新バージョン: $version");
    return version;
  }

  /// ***現在のアプリバージョンを取得***
  Future<String> getCurrentAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// ***Authentication: ログイン***
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception("ユーザーが見つかりません。");
      } else if (e.code == 'wrong-password') {
        throw Exception("パスワードが間違っています。");
      } else {
        throw Exception("認証エラー: ${e.message}");
      }
    } catch (e) {
      print("認証エラー: $e");
      throw Exception("認証中にエラーが発生しました。");
    }
  }

  /// ***Firestore: データ取得***
  Future<Map<String, dynamic>?> getDocument(String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.data();
    } on FirebaseException catch (e) {
      print("Firestoreエラー: $e");
      throw Exception("データの取得に失敗しました。通信状況を確認してください。");
    } catch (e) {
      print("予期しないエラー: $e");
      throw Exception("予期しないエラーが発生しました。");
    }
  }
  // Expenseを保存
  Future<void> saveExpense(Expense expense) async {
    final data = expense.toJson();
    await _firestore.collection('expenses').add(data);
  }

  // Incomeを保存
  Future<void> saveIncome(Income income) async {
    final data = income.toJson();
    await _firestore.collection('incomes').add(data);
  }

  // FixedCostを保存
  Future<void> saveFixedCost(FixedCost fixedCost) async {
    final data = fixedCost.toJson();
    await _firestore.collection('fixed_costs').add(data);
  }

  Future<bool> isUserCurrentlySubscribed() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('user').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final bool isSubscribed = userData['isSubscribed'] ?? false;
        final Timestamp? expiryDate = userData['subscriptionExpiry'];
        if (isSubscribed && expiryDate != null && expiryDate.toDate().isAfter(DateTime.now())) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> markUserAsSubscribed(PurchaseDetails purchaseDetails) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DateTime expiry = DateTime.now().add(const Duration(days: 31)); // 例：1ヶ月後 - 実際には検証から取得
      await _firestore.collection('user').doc(user.uid).update({
        'isSubscribed': true,
        'subscriptionExpiry': expiry,
      });
    }
  }

  Future<void> recordRestoredPurchase(PurchaseDetails restoredPurchase) async {
    User? user = _auth.currentUser;
    if (user != null && restoredPurchase.productID == 'com.gappson56.yosandekakeibo.basicPlan') {
      DateTime expiry = DateTime.now().add(const Duration(days: 31)); // 例：1ヶ月後 - 実際には検証から取得
      await _firestore.collection('user').doc(user.uid).update({
        'isSubscribed': true,
        'subscriptionExpiry': expiry,
      });
      print('購入を復元しました (Firebaseに記録)。');
    }
  }
}
