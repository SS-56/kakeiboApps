import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import '../services/firebase_service.dart';

/// アップデートダイアログの表示状態を管理する StateProvider
final updateDialogProvider = StateProvider<bool>((ref) => false);

/// アップデート確認を管理する StateNotifier
class UpdateViewModel extends StateNotifier<bool> {
  final FirebaseService _firebaseService;

  UpdateViewModel(this._firebaseService) : super(false);

  /// アップデート確認処理
  Future<void> checkForUpdate(FutureProviderRef ref) async {
    // Firebase Remote Config の初期化とフェッチ
    await _firebaseService.initialize();
    final latestVersion = _firebaseService.getLatestVersion();

    // 現在のアプリバージョンを取得
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = Version.parse(packageInfo.version);

    // 最新バージョンを比較
    final latest = Version.parse(latestVersion);

    if (latest > currentVersion) {
      ref.read(updateDialogProvider.notifier).state = true; // アップデートが必要
    } else {
      ref.read(updateDialogProvider.notifier).state = false; // アップデート不要
    }
  }
}

/// UpdateViewModel のプロバイダー
final updateViewModelProvider = StateNotifierProvider<UpdateViewModel, bool>(
      (ref) => UpdateViewModel(FirebaseService()),
);

/// FutureProvider: アップデート確認をトリガー
final checkForUpdateProvider = FutureProvider<void>((ref) async {
  final updateViewModel = ref.read(updateViewModelProvider.notifier);
  await updateViewModel.checkForUpdate(ref); // FutureProviderRef を引数に渡す
});
