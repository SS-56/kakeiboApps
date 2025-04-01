// File: test/medal_ui_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// アプリ内の各クラスのインポート（プロジェクトに合わせてパスを調整してください）
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:yosan_de_kakeibo/repositories/medal_repository.dart';

/// テスト用の Fake MedalRepository
class FakeMedalRepository implements MedalRepository {
  @override
  Future<List<Medal>> getMedals() async => [];

  @override
  Future<void> saveMedals(List<Medal> medals) async {
    // 保存処理は不要なので何もしない
  }
}

void main() {
  testWidgets('月次リセット後、UI上にメダル件数が更新される', (WidgetTester tester) async {
    // FakeMedalRepository を使って MedalViewModel を初期化
    final container = ProviderContainer(
      overrides: [
        // medalRepositoryProvider が MedalViewModel 内で利用されている前提
        // ※ medalRepositoryProvider のオーバーライドが必要な場合は、こちらも合わせて実施してください
        // ここでは MedalViewModel のコンストラクタに直接 FakeMedalRepository を渡す override を行う
        medalViewModelProvider.overrideWith((ref) => MedalViewModel(FakeMedalRepository())),
      ],
    );
    addTearDown(container.dispose);

    // テスト対象ウィジェット：MedalViewModel の state（メダル件数）を Text で表示
    final testWidget = ProviderScope(
      parent: container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, child) {
              final medals = ref.watch(medalViewModelProvider);
              return Center(
                child: Text(
                  '${medals.length} 個',
                  key: Key('medalCount'),
                ),
              );
            },
          ),
        ),
      ),
    );

    // ウィジェットをポンプして初期状態を確認（メダル件数は 0 個のはず）
    await tester.pumpWidget(testWidget);
    expect(find.text('0 個'), findsOneWidget);

    // MedalViewModel の notifier を取得し、メダル追加処理を実行
    final notifier = container.read(medalViewModelProvider.notifier);
    notifier.addMedal(
      Medal(
        type: MedalType.gold,
        description: '月次リセットで獲得',
        awardedDate: DateTime.now(),
      ),
    );

    // 状態更新後、ウィジェットの再描画を待つ
    await tester.pumpAndSettle();

    // メダル件数が 1 個になっているか確認
    expect(find.text('1 個'), findsOneWidget);
  });
}
