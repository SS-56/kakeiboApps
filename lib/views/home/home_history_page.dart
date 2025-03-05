import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'package:yosan_de_kakeibo/view_models/update_view_model.dart';

class HomeHistoryPage extends ConsumerWidget {
  const HomeHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ホーム画面 過去データ"),
        automaticallyImplyLeading: false, // 既存: leadingなしで右上に閉じるボタン
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHomeData(ref), // 下記メソッドで24件取得
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("過去データがありません"));
          }

          final dataList = snapshot.data!;
          // ★ 変更: 一覧表示 (ListView) に切り替え
          return ListView.builder(
            itemCount: dataList.length, // 最大24件
            itemBuilder: (context, index) {
              final data = dataList[index];
              // metadata がある場合は合計などをそこから取得
              final totalIncome = data['metadata']?['totalIncome'] ?? 0;
              final totalSpent  = data['metadata']?['totalSpent'] ?? 0;
              final remain      = data['metadata']?['remainingBalance'] ?? 0;
              final docId       = data['docId'] ?? '(unknown)';

              return Card(
                child: ListTile(
                  title: Text("月ID: $docId"),
                  subtitle: Text("総収入: $totalIncome / 使った金額: $totalSpent / 残額: $remain"),
                  onTap: () {
                    // さらに詳細を表示 or ダイアログで中身を確認
                    _showDetailDialog(context, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// uid を取得し、FirebaseRepository に渡す。24件取得するように修正。
  Future<List<Map<String, dynamic>>> _fetchHomeData(WidgetRef ref) async {
    final sp = await SharedPreferences.getInstance();
    final uid = sp.getString('firebase_uid') ?? '';
    if (uid.isEmpty) {
      return [];
    }

    final repo = ref.read(firebaseRepositoryProvider);
    // loadHomeHistoryを修正 or 追加して、.limit(24) で取得する実装に変更。
    // 例: repo.loadHomeHistory(uid) => 24件取得
    return await repo.loadHomeHistory(uid);
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("詳細（編集不可）"),
          content: SingleChildScrollView(
            child: Text(data.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("閉じる"),
            ),
          ],
        );
      },
    );
  }
}
