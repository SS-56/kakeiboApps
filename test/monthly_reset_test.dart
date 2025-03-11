import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// lib
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';
// mockito
import 'mocks/mock_medal_repository.mocks.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('月次リセット実行 -> メダル付与 -> stateが増える', () async {
    // 1) Mock
    final mockRepo = MockMedalRepository();
    when(mockRepo.getMedals()).thenAnswer((_) async => []);
    final container = ProviderContainer(
      overrides: [
        medalViewModelProvider.overrideWith(
              (ref) => MedalViewModel(mockRepo)..loadMedals(),
        ),
      ],
    );

    // 2) 初期状態 => state = []
    final medals0 = container.read(medalViewModelProvider);
    expect(medals0.length, 0);

    // 3) "月次リセット" ロジックを模擬
    //   => addMedal(...)
    container.read(medalViewModelProvider.notifier).addMedal(
      Medal(
        type: MedalType.gold,
        description: '月次リセットで獲得',
        awardedDate: DateTime.now(),
      ),
    );

    // 4) stateが更新されているか確認
    final medals1 = container.read(medalViewModelProvider);
    expect(medals1.length, 1);
    expect(medals1.first.type, MedalType.gold);
  });
}
