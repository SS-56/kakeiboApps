// view_models/medal_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';
import 'package:yosan_de_kakeibo/repositories/medal_repository.dart';

/// メダル情報を管理する StateNotifier
/// - load/save でリポジトリへ保存
/// - checkAndAwardMedal で要件判定 -> state に追加
final medalViewModelProvider = StateNotifierProvider<MedalViewModel, List<Medal>>((ref) {
  final repo = ref.watch(medalRepositoryProvider);
  return MedalViewModel(repo);
});

class MedalViewModel extends StateNotifier<List<Medal>> {
  final MedalRepository _repo;

  MedalViewModel(this._repo) : super([]) {
    loadMedals();
  }

  /// リポジトリからメダル一覧をロード
  Future<void> loadMedals() async {
    final loaded = await _repo.getMedals();
    state = loaded;
  }

  /// リポジトリへメダル一覧をセーブ
  Future<void> saveMedals() async {
    await _repo.saveMedals(state);
  }

  /// 現在の(最後に獲得した)メダルを返す例
  MedalType getCurrentMedalType() {
    if (state.isEmpty) return MedalType.none;
    // 例: 最後に獲得したメダル
    return state.last.type;
  }

  /// メダル付与判定
  /// ※ 要件例:
  ///  - 金: (貯金を1円も減らさず) + (総額15%未満にならない)
  ///  - 銀: (貯金を減らしたが 50~99%程度残っている) + (総額10%未満にならない)
  ///  - 銅: (貯金0円になっても 総額5%未満にならない)
  ///  - それ以外 none
  ///
  /// ここでは:
  ///  totalIncome: 総収入(基準)
  ///  remainingBalance: 残額
  ///  oldSaving: 貯金Before
  ///  newSaving: 貯金After
  ///  isPaidUser: 課金状態
  Future<void> checkAndAwardMedal({
    required double totalIncome,
    required double remainingBalance,
    required double oldSaving,
    required double newSaving,
    required bool isPaidUser,
  }) async {
    // 課金じゃなければメダルなし
    if (!isPaidUser) {
      return;
    }

    // 残額比
    final ratio = (totalIncome>0) ? (remainingBalance / totalIncome) : 0.0;

    // 1) 金メダル
    //   - 貯金を1円も減らさない => newSaving == oldSaving
    //   - ratio >= 0.15
    if (newSaving == oldSaving && ratio >= 0.15) {
      addMedal(
        Medal(
          type: MedalType.gold,
          description: "貯金を減らさず総額15%を切らなかった",
          awardedDate: DateTime.now(),
        ),
      );
      return;
    }

    // 2) 銀メダル
    //   - newSaving < oldSaving (貯金を減らした)
    //   - 50%~99%ほど残り => (newSaving / oldSaving) between 0.50 and 0.99
    //   - ratio >= 0.10
    final savingRatio = (oldSaving>0) ? (newSaving/oldSaving) : 0.0;
    if (newSaving < oldSaving &&
        savingRatio>=0.50 && savingRatio<0.99 &&
        ratio>=0.10
    ) {
      addMedal(
        Medal(
          type: MedalType.silver,
          description: "貯金を一部使っても10%切らなかった",
          awardedDate: DateTime.now(),
        ),
      );
      return;
    }

    // 3) 銅メダル
    //   - newSaving == 0
    //   - ratio>=0.05
    if (newSaving == 0 && ratio>=0.05) {
      addMedal(
        Medal(
          type: MedalType.bronze,
          description: "貯金0でも5%切らなかった",
          awardedDate: DateTime.now(),
        ),
      );
      return;
    }

    // 4) none => do nothing
  }

  /// 内部メソッド: stateにメダルを追加し、保存
  void addMedal(Medal medal) {
    state = [...state, medal];
    saveMedals();
  }
}
