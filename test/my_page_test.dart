import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ===== ここからlib =====
import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/views/my_page/my_page.dart';
// =====================

// mockito関連
import 'package:mockito/mockito.dart';
import 'mocks/mock_medal_repository.mocks.dart';

void main() {
  testWidgets('月次リセットでメダルが付与され、UIに表示される', (WidgetTester tester) async {
    // 1) MockMedalRepositoryを作成
    final mockRepo = MockMedalRepository();

    // 2) getMedals() の初期値を空配列に
    when(mockRepo.getMedals()).thenAnswer((_) async => []);

    // 3) ProviderScope で MedalViewModel を差し替え
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medalViewModelProvider.overrideWith(
                (ref) => MedalViewModel(mockRepo)..loadMedals(),
          ),
        ],
        child: const MaterialApp(
          home: MyPage(), // ★ 本番のMyPageを利用
        ),
      ),
    );

    // 4) まず初期表示を待つ
    await tester.pumpAndSettle();

    // 4-1) 初期状態 => "0 個" があるはず
    expect(find.text('0 個'), findsOneWidget);

    // ============ ここで「月次リセット」を実行する想定 ============
    // 本来はlibでやるが、テストだけで再現するために
    // "月初( day==1 ) => checkAndAwardMedal()" 的なロジックを
    // 直接呼ぶ or StateNotifierを呼び出す

    // 5) "月次リセットが成功した" 状態を再現する
    //   => ここでは "メダル1個付与" と仮定
    //   => monthly_reset_service の流れを模擬
    //   => つまり: medalViewModelProvider.notifier.addMedal(...) を呼ぶ
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MyPage)),
    );
    container.read(medalViewModelProvider.notifier).addMedal(
      Medal(
        type: MedalType.gold,
        description: '月次リセットで獲得',
        awardedDate: DateTime.now(),
      ),
    );

    // 6) UI再描画
    await tester.pumpAndSettle();

    // 7) "1 個" と表示されていればOK
    expect(find.text('1 個'), findsOneWidget);
  });
}
