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

    // monthly_data の 'metadata' があるdocだけ表示
    final filtered = docs.where((d) => d['metadata'] != null).toList();
    setState(() {
      monthlyDocs = filtered;
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
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        body: const Center(child: Text("過去データがありません")),
      );
    }

    final doc = monthlyDocs[_currentIndex];
    final monthId = doc['monthId'] ?? '(unknown)';
    final meta = doc['metadata'] as Map<String,dynamic>;

    // 小数点を表示しないように
    final wasteVal = (meta['wasteTotal']      as double? ?? 0).toStringAsFixed(0);
    final totalSpent= (meta['totalSpent']     as double? ?? 0).toStringAsFixed(0);
    final nonVal   = (meta['nonWaste']        as double? ?? 0).toStringAsFixed(0);
    final goalVal  = (meta['goalSaving']      as double? ?? 0).toStringAsFixed(0);
    final thisSav  = (meta['thisMonthSaving'] as double? ?? 0).toStringAsFixed(0);
    final totSav   = (meta['totalSaving']     as double? ?? 0).toStringAsFixed(0);

    // PieChart用 double
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
        actions: _buildRightButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("月: $monthId",
                style: const TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
            const SizedBox(height:16),

            // 使った金額 (PieChart) Cardをmy_page.dartと同じレイアウトに近づける
            Card(
              margin: const EdgeInsets.only(bottom:16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
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

            // 貯金関連のCard
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

  // ------------------------------------------------------------------
  Widget? _buildLeftButton() {
    // 2ページ目以降 => leftに <
    if (_currentIndex > 0) {
      return IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: _goPrevPage,
      );
    }
    return null;
  }

  List<Widget> _buildRightButton() {
    // 1ページ目 & docs>1 => >
    if (_currentIndex == 0 && monthlyDocs.length > 1) {
      return [
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _goNextPage,
        )
      ];
    }
    return [];
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
