import 'package:shared_preferences/shared_preferences.dart';

Future<void> savePageIndex(int index) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('page_index', index);
}
