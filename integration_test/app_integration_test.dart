// File: integration_test/app_integration_test.dart

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';

// アプリ内ファイルのインポート（パスはプロジェクトに合わせて調整）
import 'package:yosan_de_kakeibo/views/my_page/my_page.dart';
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/view_models/subscription_status_view_model.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';

// テスト用の FakeFirebaseRepository（ファイル: test/utils/fake_firebase_repository.dart で定義済みとする）


import '../test/utils/fake_firebase_repository.dart';

/// テスト用の FakeSubscriptionStatusNotifier：
/// Firebase 関連の処理を回避し、初期状態を 'basic' に設定する
class FakeSubscriptionStatusNotifier extends SubscriptionStatusViewModel {
  FakeSubscriptionStatusNotifier(Ref ref) : super(ref) {
    state = SubscriptionStatusViewModel.basic;
  }

  @override
  Future<void> syncWithFirebase() async {
    // Firebase 呼び出しを回避するため、何もしない
  }
}

void main() {
  // 統合テスト用バインディングの初期化
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('月次処理後、マイページに金メダルアイコンが表示される', (WidgetTester tester) async {
    // ProviderContainer のオーバーライドで、Firebase に依存するプロバイダーを Fake に置き換える
    final container = ProviderContainer(
      overrides: [
        // subscriptionStatusProvider を FakeSubscriptionStatusNotifier でオーバーライド
        subscriptionStatusProvider.overrideWith((ref) => FakeSubscriptionStatusNotifier(ref)),
        // firebaseRepositoryProvider を FakeFirebaseRepository に置き換え
        firebaseRepositoryProvider.overrideWithValue(FakeFirebaseRepository()),
      ],
    );
    addTearDown(container.dispose);

    // デバッグ用リスナーを追加（MedalViewModel の状態更新を確認）
    container.listen<List<Medal>>(medalViewModelProvider, (_, state) {
      print('[DEBUG] Medals updated: $state');
    });

    // MyPage を表示する
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: const MaterialApp(
          home: MyPage(),
        ),
      ),
    );

    // 初期状態では金メダルアイコンが表示されていないことを確認
    expect(find.byKey(const Key('goldMedalIcon')), findsNothing);

    // MedalViewModel の notifier を利用して、条件を満たす金メダル付与処理を実行
    final medalNotifier = container.read(medalViewModelProvider.notifier);
    await medalNotifier.checkAndAwardMedal(
      totalIncome: 1000,           // 総収入 1000
      remainingBalance: 200,       // 比率 0.2 (条件: 0.15以上)
      oldSaving: 100,              // 減っていないので新旧が同じ
      newSaving: 100,
      isPaidUser: true,            // 課金ユーザー
    );

    // UI 更新のため、再ビルドを待つ（必要に応じて遅延を調整）
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 金メダルアイコン（キー 'goldMedalIcon'）が表示されることを検証
    expect(find.byKey(const Key('goldMedalIcon')), findsOneWidget);
  });
}
