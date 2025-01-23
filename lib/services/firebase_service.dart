import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FirebaseService {
  final FirebaseRemoteConfig _remoteConfig;

  FirebaseService() : _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    print("Firebase Remote Config 初期化開始...");

    // アプリの現在バージョンを取得
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // // デフォルト値として現在のバージョンを使用
    // await _remoteConfig.setDefaults(<String, dynamic>{
    //   'latest_app_version': currentVersion, // 可変値として現在のバージョンを設定
    // });

    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      // minimumFetchInterval: const Duration(hours: 1), // 最小フェッチ間隔
      minimumFetchInterval: Duration.zero, // フェッチ間隔を0に設定
    ));

    final success = await _remoteConfig.fetchAndActivate();
    print("フェッチ成功: $success");
    if (!success) {
      print("フェッチに失敗しました。キャッシュ値またはデフォルト値を使用します。");
    }

    // await _remoteConfig.fetchAndActivate();
    // print("Firebase Remote Config 初期化完了");
  }

  String getLatestVersion() {
    final version = _remoteConfig.getString('latest_app_version');
    print("取得した最新バージョン: $version");
    return version;
  }
}
