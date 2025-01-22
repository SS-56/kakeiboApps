import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';

class UpdateViewModel extends StateNotifier<bool> {
  final FirebaseService _firebaseService;

  UpdateViewModel(this._firebaseService) : super(false);

  Future<void> checkForUpdate(String currentVersion) async {
    await _firebaseService.initialize();
    final latestVersion = _firebaseService.getLatestVersion();

    if (latestVersion.compareTo(currentVersion) > 0) {
      state = true;
    } else {
      state = false;
    }
  }
}

final updateViewModelProvider = StateNotifierProvider<UpdateViewModel, bool>(
      (ref) => UpdateViewModel(FirebaseService()),
);
