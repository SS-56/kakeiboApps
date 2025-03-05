import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yosan_de_kakeibo/repositories/firebase_repository.dart';
import 'package:pie_chart/pie_chart.dart';

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
    // 24件
    final docs = await repo.loadMyPageHistory(uid);

    // metadataがあるもののみ
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
          automaticallyImplyLeading: false, // ここを追加
          // leadingもactionsも置かない => 画面に戻るには?
          // もし戻りボタンが必要なら右に出すなど
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

    // 複数ページ => _currentIndex
    final doc = monthlyDocs[_currentIndex];
    final monthId = doc['monthId'] ?? '(unknown)';
    final meta = doc['metadata'] as Map<String,dynamic>;
    final waste = (meta['wasteTotal'] as double? ?? 0).toStringAsFixed(0);
    final spent = (meta['totalSpent'] as double? ?? 0).toStringAsFixed(0);
    final non   = (meta['nonWaste']   as double? ?? 0).toStringAsFixed(0);

    final dataMap = {
      "浪費": double.parse(waste),
      "非浪費": double.parse(non),
    };

    final goal = (meta['goalSaving'] as double? ?? 0).toStringAsFixed(0);
    final thisSav = (meta['thisMonthSaving'] as double? ?? 0).toStringAsFixed(0);
    final totSav  = (meta['totalSaving'] as double? ?? 0).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // important
        title: const Text("マイページ 過去データ"),
        leading: _buildLeftButton(),
        actions: _buildRightButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("月: $monthId", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("使った金額: $spent 円"),
                    Text("浪費合計: $waste 円"),
                    Text("差引金額: $non 円"),
                    const SizedBox(height:12),
                    PieChart(
                      dataMap: dataMap,
                      chartType: ChartType.ring,
                      chartValuesOptions: const ChartValuesOptions(
                        showChartValuesInPercentage: true,
                        decimalPlaces: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top:16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("目標貯金額: $goal 円"),
                    Text("当月貯金額: $thisSav 円"),
                    Text("貯金の総額: $totSav 円"),
                  ],
                ),
              ),
            ),
            // メダル表示に gold.png / silver.png / bronze.png
            // e.g. Image.asset("assets/images/gold.png", width:32, height:32)
          ],
        ),
      ),
    );
  }

  Widget? _buildLeftButton() {
    // 2ページ目以降 => index>0 => leftに<
    if (_currentIndex > 0) {
      return IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: _goPrevPage,
      );
    }
    return null; // 1ページ目 => null
  }

  List<Widget> _buildRightButton() {
    // 1ページ目 & docs>1 => rightに >
    if (_currentIndex == 0 && monthlyDocs.length>1) {
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
