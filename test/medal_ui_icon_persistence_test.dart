// File: test/medal_ui_icon_persistence_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// アプリ内の各クラスのインポート（パスはプロジェクト構成に合わせて調整してください）
import 'package:yosan_de_kakeibo/view_models/medal_view_model.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:yosan_de_kakeibo/repositories/medal_repository.dart';

/// テスト用の Fake MedalRepository
/// 内部でメダルリストを保持し、save/getをシミュレーションする
class FakeMedalRepository implements MedalRepository {
  List<Medal> _medals = [];

  @override
  Future<List<Medal>> getMedals() async => _medals;

  @override
  Future<void> saveMedals(List<Medal> medals) async {
    _medals = medals;
  }
}

/// マイページとして、メダルがあればアイコン、無ければテキストを表示するウィジェット
class TestMyPage extends ConsumerWidget {
  const TestMyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medals = ref.watch(medalViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text("My Page")),
      body: Center(
        child: medals.isNotEmpty
            ? Icon(Icons.emoji_events, key: const Key('medalIcon'))
            : const Text('No medal', key: Key('noMedalText')),
      ),
    );
  }
}

void main() {
  testWidgets('保存処理後も、再起動時にマイページにメダルアイコンが表示される', (WidgetTester tester) async {
    // FakeMedalRepository のインスタンスを作成（これで保存処理をシミュレーション）
    final fakeRepo = FakeMedalRepository();

    // 初回の ProviderContainer を作成
    ProviderContainer container = ProviderContainer(
      overrides: [
        medalViewModelProvider.overrideWith((ref) => MedalViewModel(fakeRepo)),
      ],
    );
    addTearDown(container.dispose);

    // 初回のUIを構築（TestMyPageを表示）
    await tester.pumpWidget(
      ProviderScope(
        parent: container,
        child: const MaterialApp(
          home: TestMyPage(),
        ),
      ),
    );

    // 初期状態：保存されているメダルは無いので「No medal」が表示される
    expect(find.byKey(const Key('noMedalText')), findsOneWidget);
    expect(find.byKey(const Key('medalIcon')), findsNothing);

    // メダルを追加（例：ゴールドメダル）
    container.read(medalViewModelProvider.notifier).addMedal(
      Medal(
        type: MedalType.gold,
        description: '月次リセットで獲得',
        awardedDate: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();

    // メダル追加後、アイコンが表示される
    expect(find.byKey(const Key('medalIcon')), findsOneWidget);

    // 「アプリの再起動」をシミュレーションするため、ProviderContainerを破棄
    container.dispose();

    // ウィジェットツリーをクリア（空のウィジェットをpumpする）
    await tester.pumpWidget(const SizedBox.shrink());

    // 新たな ProviderContainer を作成（同じ FakeMedalRepository を使用）
    final newContainer = ProviderContainer(
      overrides: [
        medalViewModelProvider.overrideWith((ref) => MedalViewModel(fakeRepo)),
      ],
    );
    addTearDown(newContainer.dispose);

    // 再起動後のUIを構築
    await tester.pumpWidget(
      ProviderScope(
        parent: newContainer,
        child: const MaterialApp(
          home: TestMyPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 保存されたメダルがロードされ、再びメダルアイコンが表示される
    expect(find.byKey(const Key('medalIcon')), findsOneWidget);
  });
}
