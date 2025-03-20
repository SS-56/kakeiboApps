import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  List<Map<String,dynamic>> monthlyDocs = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sp = await SharedPreferences.getInstance();
    final uid = sp.getString('firebase_uid') ?? 'dummy';

    final repo = ref.read(firebaseRepositoryProvider);
    // 24件取得
    final docs = await repo.loadMyPageHistory(uid);

    // 既に finalizeMonth が毎回 metadata を付けて保存するので、基本的に null は無いはず
    // もし念のため null があっても取り込む
    setState(() {
      monthlyDocs = docs;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyDocs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("マイページ 過去データ"),
          automaticallyImplyLeading: false,
          actions: [
            // 右上に “＞” で戻る
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: const Center(
          child: Text(
            "過去データがありません\n\n(まだ1度も finalizeMonth が呼ばれていない可能性)",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final doc = monthlyDocs[_currentIndex];
    final docId = doc['docId'] ?? '(unknown)';
    final meta = doc['metadata'] as Map<String,dynamic>?;

    // メタデータ無いときは 0表示 or fallback
    final wasteVal   = (meta?['wasteTotal']      as double? ?? 0).toStringAsFixed(0);
    final totalSpent = (meta?['totalSpent']      as double? ?? 0).toStringAsFixed(0);
    final nonVal     = (meta?['nonWaste']        as double? ?? 0).toStringAsFixed(0);
    final goalVal    = (meta?['goalSaving']      as double? ?? 0).toStringAsFixed(0);
    final thisSav    = (meta?['thisMonthSaving'] as double? ?? 0).toStringAsFixed(0);
    final totSav     = (meta?['totalSaving']     as double? ?? 0).toStringAsFixed(0);

    final wasteNum = double.parse(wasteVal);
    final nonNum   = double.parse(nonVal);

    final dataMap = {
      "浪費": wasteNum,
      "非浪費": nonNum,
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("マイページ 過去データ"),
        leading: _buildLeftButton(),
        actions: [
          // 右上に "＞" で Navigator.pop
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("月ID: $docId",
                style: const TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
            const SizedBox(height:16),

            Card(
              margin: const EdgeInsets.only(bottom:16),
              child: Column(
                children: [
                  const SizedBox(height:16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left:40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("使った金額: $totalSpent 円"),
                          Text("浪費合計: $wasteVal 円"),
                          Text("差引金額: $nonVal 円"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height:20),
                  PieChart(
                    dataMap: dataMap,
                    chartType: ChartType.ring,
                    chartRadius: MediaQuery.of(context).size.shortestSide * 0.3,
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValuesInPercentage: true,
                      decimalPlaces: 0,
                    ),
                  ),
                  const SizedBox(height:30),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.only(bottom:16),
              child: Column(
                children: [
                  const SizedBox(height:8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left:40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("目標貯金額: $goalVal 円"),
                          const SizedBox(height:8),
                          Text("当月貯金額: $thisSav 円"),
                          const SizedBox(height:8),
                          Text("貯金の総額: $totSav 円"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height:16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildLeftButton() {
    if (_currentIndex>0) {
      return IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: _goPrevPage,
      );
    }
    return null;
  }

  void _goNextPage() {
    if (_currentIndex < monthlyDocs.length -1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _goPrevPage() {
    if (_currentIndex>0) {
      setState(() {
        _currentIndex--;
      });
    }
  }
}
