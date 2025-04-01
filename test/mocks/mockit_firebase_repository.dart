// // File: test/mockit_firebase_repository_test.dart
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// // 以下、各パスは実際のプロジェクト構成に合わせてください。
// import 'package:yosan_de_kakeibo/handlers/monthly_data_handler.dart';
// import 'package:yosan_de_kakeibo/providers/page_providers.dart'; // firebaseRepositoryProvider などの定義
// import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
// import 'package:yosan_de_kakeibo/view_models/settings_view_model.dart'; // startDayProvider、StartDayNotifier の定義
// import 'fake_widget_ref.dart';
//
// /// FirebaseRepository の Mockito 用モッククラス
// class MockFirebaseRepository extends Mock implements FirebaseRepository {}
//
// /// startDayProvider 用の FakeStartDayNotifier
// /// ※ StartDayNotifier を継承している必要があります。
// class FakeStartDayNotifier extends StartDayNotifier {
//   FakeStartDayNotifier() : super(10);
// }
//
// void main() {
//   test('finalizeMonth が FirebaseRepository の saveMonthlyData を呼び出す', () async {
//     // 1. モックの FirebaseRepository を生成
//     final mockFirebaseRepo = MockFirebaseRepository();
//
//     // 2. ProviderContainer を作成し、必要なプロバイダーをオーバーライドする
//     final container = ProviderContainer(
//       overrides: [
//         // firebaseRepositoryProvider をモックに上書き（Provider の場合は overrideWith を使用）
//         firebaseRepositoryProvider.overrideWith((ref) => mockFirebaseRepo),
//         // startDayProvider を FakeStartDayNotifier に置き換え、初期値を「10」に固定する
//         startDayProvider.overrideWith((ref) => FakeStartDayNotifier()),
//         // ※ finalizeMonth 内で利用している他のプロバイダーも必要に応じてオーバーライドしてください
//       ],
//     );
//
//     // 3. FakeWidgetRef を生成（ProviderContainer を内部に持たせる）
//     final fakeRef = FakeWidgetRef(container);
//
//     // 4. finalizeMonth を呼び出す
//     await finalizeMonth(fakeRef);
//
//     // 5. saveMonthlyData が、正しい named parameter で呼ばれたか検証
//     verify(mockFirebaseRepo.saveMonthlyData(
//       uid: anyNamed('uid'),
//       yyyyMM: anyNamed('yyyyMM'),
//       incomes: argThat(isA<List<Income>>()),
//       fixedCosts: argThat(isA<List<FixedCost>>()),
//       expenses: argThat(isA<List<Expense>>()),
//       metadata: anyNamed('metadata'),
//     )).called(1);
//   });
// }
