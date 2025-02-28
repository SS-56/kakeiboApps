// views/my_page/history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String uid = '';
  List<Map<String, dynamic>> monthlyDocs = []; // 履歴データ

  @override
  void initState() {
    super.initState();
    _loadUidAndFetchData();
  }

  Future<void> _loadUidAndFetchData() async {
    final sp = await SharedPreferences.getInstance();
    final userId = sp.getString('firebase_uid') ?? 'dummy';
    setState(() { uid = userId; });

    // 取得
    final repo = ref.read(firebaseRepositoryProvider);
    final docs = await _fetchAllMonthlyData(repo, userId);
    setState(() {
      monthlyDocs = docs;
    });
  }

  /// 例: user/{uid}/monthly_data を取得して List化
  Future<List<Map<String,dynamic>>> _fetchAllMonthlyData(
      FirebaseRepository repo,
      String uid,
      ) async {
    // Firestore usage directly or via repo.
    final fs = FirebaseFirestore.instance;
    final snap = await fs
        .collection('user')
        .doc(uid)
        .collection('monthly_data')
        .orderBy('timestamp', descending:true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      data['monthId'] = doc.id; // yyyyMM
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("過去履歴(閲覧のみ)"),
        ),
        body: monthlyDocs.isEmpty
            ? Center(child: Text("履歴がありません"))
            : ListView.builder(
          itemCount: monthlyDocs.length,
          itemBuilder: (ctx, i) {
            final m = monthlyDocs[i];
            final monthId = m['monthId']; // yyyyMM
            // incomes/fixedCosts/expenses => read-only
            return Card(
              child: ListTile(
                title: Text("月: $monthId"),
                subtitle: Text("incomes: ${(m['incomes'] as List).length}件, "
                    "fixed: ${(m['fixedCosts'] as List).length}件, "
                    "expenses: ${(m['expenses'] as List).length}件"),
                onTap: (){
                  // detail page? or just show dialog
                  _showDetailDialog(m);
                },
              ),
            );
          },
        )
    );
  }

  void _showDetailDialog(Map<String,dynamic> monthData){
    showDialog(
      context: context,
      builder: (_){
        return AlertDialog(
          title: Text("詳細（編集不可）"),
          content: SingleChildScrollView(
            child: Text(monthData.toString()),
          ),
          actions:[
            TextButton(
              onPressed: ()=>Navigator.pop(context),
              child: Text("閉じる"),
            )
          ],
        );
      },
    );
  }
}
