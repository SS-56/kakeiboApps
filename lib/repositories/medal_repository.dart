// repositories/medal_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/models/medal.dart';

/// メダル情報の保存・取得インターフェイス
/// 実装: SharedPreferences でも Firebase でもOK
abstract class MedalRepository {
  Future<List<Medal>> getMedals();
  Future<void> saveMedals(List<Medal> medals);
}

/// 例: SharedPreferences実装の場合
/// ここでは詳細は省略して、仮のダミーを示す
class MedalRepositoryImpl implements MedalRepository {
  @override
  Future<List<Medal>> getMedals() async {
    // TODO: SharedPreferences等から読み込む
    return [];
  }

  @override
  Future<void> saveMedals(List<Medal> medals) async {
    // TODO: JSON化して保存
  }
}

// ↑ これらに加えて、Providerを定義
final medalRepositoryProvider = Provider<MedalRepository>((ref) {
  return MedalRepositoryImpl();
});
