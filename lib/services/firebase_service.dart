import 'package:firebase_remote_config/firebase_remote_config.dart';

class FirebaseService {
  final FirebaseRemoteConfig _remoteConfig;

  FirebaseService() : _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _remoteConfig.fetchAndActivate();
  }

  String getLatestVersion() {
    return _remoteConfig.getString('latest_app_version');
  }
}
