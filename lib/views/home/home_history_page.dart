import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';

class HomeHistoryPage extends ConsumerStatefulWidget {
  const HomeHistoryPage({Key? key}) : super(key: key);

  @override
  HomeHistoryPageState createState() => HomeHistoryPageState();
}

class HomeHistoryPageState extends ConsumerState<HomeHistoryPage> {
  List<Map<String,dynamic>> monthlyDocs = [];
  int _currentIndex = 0; // docインデックス: 0を最新、1が1ヶ月前...等

  @override
  void initState() {
    super.initState();
    _loadPastData();
  }

  // 過去データ(例: 24件)をロード
  Future<void> _loadPastData() async {
    final sp = await SharedPreferences.getInstance();
    final uid = sp.getString('firebase_uid') ?? '';
    if (uid.isEmpty) {
      setState(() {
        monthlyDocs = [];
        _currentIndex = 0;
      });
      return;
    }
    final repo = ref.read(firebaseRepositoryProvider);
    // loadHomeHistory: 24件取得を想定 => docsが新しい順に並んでいるか、古い順かは要確認
    final docs = await repo.loadHomeHistory(uid);

    // 例: 最新 => index=0, その後 index=1,2... が過去
    setState(() {
      monthlyDocs = docs;
      // monthlyDocs[0] を最新として扱うならここ
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyDocs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("ホーム画面 過去実績"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: const Center(
          child: Text("過去データがありません"),
        ),
      );
    }

    // 現在の doc
    final doc = monthlyDocs[_currentIndex];
    final docId = doc['docId'] ?? '(unknown)';

    // たとえば doc['metadata'] に支出・残額等が保存されている前提
    final meta = doc['metadata'] as Map<String,dynamic>?;

    final totalSpent   = meta?['totalSpent']     ?? 0;
    final remain       = meta?['remainingBalance']?? 0;
    final totalWaste   = meta?['wasteTotal']     ?? 0;
    final totalIncome  = meta?['totalIncome']    ?? 0;
    // etc... => ホーム画面に合わせてキーをそろえてください

    // 左(＜) が押せるか
    final canGoLeft  = (_currentIndex < monthlyDocs.length -1);
    // 右(＞) が押せるか
    final canGoRight = (_currentIndex > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ホーム画面 過去実績"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ＜ docId ＞ のナビゲーション
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canGoLeft ? _goOlder : null, // もっと古い月
                ),
                Text("月ID: $docId"),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: canGoRight ? _goNewer : null, // 新しい月
                ),
              ],
            ),
            // ホーム画面のUIそのまま再現 (読み取り専用)
            _buildHomeLikeUI(
              totalSpent: totalSpent,
              remain: remain,
              totalWaste: totalWaste,
              totalIncome: totalIncome,
            ),
          ],
        ),
      ),
    );
  }

  // 前(古い月)
  void _goOlder() {
    if (_currentIndex < monthlyDocs.length-1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  // 次(新しい月)
  void _goNewer() {
    if (_currentIndex>0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  // ★ ホーム画面のUIを再現する。ここでは簡易サンプル
  Widget _buildHomeLikeUI({
    required num totalSpent,
    required num remain,
    required num totalWaste,
    required num totalIncome,
  }) {
    // ここに実際のホーム画面と同じWidgetツリーを並べる
    // 例: “支出合計”, “残額”, “浪費合計”, etc
    // すべて readOnly => ユーザーが編集できない
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("総収入: $totalIncome 円", style: const TextStyle(fontSize:16)),
          const SizedBox(height:8),
          Text("使った金額: $totalSpent 円", style: const TextStyle(fontSize:16)),
          const SizedBox(height:8),
          Text("残額: $remain 円", style: const TextStyle(fontSize:16)),
          const SizedBox(height:8),
          Text("浪費合計: $totalWaste 円", style: const TextStyle(fontSize:16)),

          // ホーム画面で TextField を使っていた箇所は readOnly: true で対応する
          // ...
        ],
      ),
    );
  }
}
