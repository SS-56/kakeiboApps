// File: test/medal_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

// アプリ内の各クラスのインポート（パスはプロジェクト構成に合わせてください）
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:yosan_de_kakeibo/repositories/medal_repository.dart';

// 生成済みのモックを利用
import 'mock_medal_repository.mocks.dart';


void main() {
  group('MedalViewModel のテスト', () {
    late MockMedalRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      // モックリポジトリの初期設定
      mockRepo = MockMedalRepository();
      // loadMedals 内で getMedals() を呼んでいるので、空リストを返すように設定
      when(mockRepo.getMedals()).thenAnswer((_) async => []);
      container = ProviderContainer(
        overrides: [
          medalViewModelProvider.overrideWith((ref) => MedalViewModel(mockRepo)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('課金していない場合は、メダルが付与されない', () async {
      final viewModel = container.read(medalViewModelProvider.notifier);
      await viewModel.checkAndAwardMedal(
        totalIncome: 1000,
        remainingBalance: 200,
        oldSaving: 100,
        newSaving: 80,
        isPaidUser: false,
      );

      final medals = container.read(medalViewModelProvider);
      expect(medals, isEmpty);
    });

    test('ゴールドメダル: 貯金を減らさず、ratio >= 0.15 の場合', () async {
      final viewModel = container.read(medalViewModelProvider.notifier);
      // totalIncome 1000, remainingBalance 200 -> ratio = 0.2
      // newSaving == oldSaving であるため、ゴールドの条件に合致
      await viewModel.checkAndAwardMedal(
        totalIncome: 1000,
        remainingBalance: 200,
        oldSaving: 100,
        newSaving: 100,
        isPaidUser: true,
      );

      final medals = container.read(medalViewModelProvider);
      expect(medals.length, 1);
      expect(medals.first.type, MedalType.gold);
    });

    test('銀メダル: 貯金が減って、savingRatio が 0.50〜0.99 かつ ratio >= 0.10 の場合', () async {
      final viewModel = container.read(medalViewModelProvider.notifier);
      // 例: oldSaving=100, newSaving=70 -> savingRatio=0.70;
      // totalIncome 1000, remainingBalance 150 -> ratio = 0.15
      await viewModel.checkAndAwardMedal(
        totalIncome: 1000,
        remainingBalance: 150,
        oldSaving: 100,
        newSaving: 70,
        isPaidUser: true,
      );

      final medals = container.read(medalViewModelProvider);
      expect(medals.length, 1);
      expect(medals.first.type, MedalType.silver);
    });

    test('銅メダル: newSaving == 0 かつ ratio >= 0.05 の場合', () async {
      final viewModel = container.read(medalViewModelProvider.notifier);
      // 例: oldSaving=100, newSaving=0; totalIncome 1000, remainingBalance 60 -> ratio = 0.06
      await viewModel.checkAndAwardMedal(
        totalIncome: 1000,
        remainingBalance: 60,
        oldSaving: 100,
        newSaving: 0,
        isPaidUser: true,
      );

      final medals = container.read(medalViewModelProvider);
      expect(medals.length, 1);
      expect(medals.first.type, MedalType.bronze);
    });

    test('条件に合致しない場合はメダル付与されない', () async {
      final viewModel = container.read(medalViewModelProvider.notifier);
      // 例: いずれの条件も満たさないケース
      await viewModel.checkAndAwardMedal(
        totalIncome: 1000,
        remainingBalance: 50,   // ratio = 0.05（ゴールドは 0.15、銀は 0.10 以上が必要）
        oldSaving: 100,
        newSaving: 90,          // newSaving < oldSaving だが savingRatio は 0.9 だが ratio が不足
        isPaidUser: true,
      );

      final medals = container.read(medalViewModelProvider);
      expect(medals, isEmpty);
    });
  });
}
