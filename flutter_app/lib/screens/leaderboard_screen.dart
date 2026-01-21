import 'dart:convert';  // JSON 파싱을 위해 필요
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/menu_bottom.dart';
import 'package:http/http.dart' as http;  // HTTP 요청을 위해 필요

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _scoreList = [];  // 서버에서 받은 데이터를 저장
  bool _isLoading = true;  // 데이터 로딩 상태

  @override
  void initState() {
    super.initState();
    _fetchScores();  // 점수 목록을 가져오는 함수 호출
  }

  // 서버로부터 점수 목록을 가져오는 함수
  Future<void> _fetchScores() async {
    setState(() {
      _isLoading = true; // 로딩 상태를 true로 변경
    });

    try {
      final response = await http.get(Uri.parse('http://192.168.137.245:5000/api/submit-score'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _scoreList = data['stored_data'] ?? [];  // 서버로부터 받은 데이터 저장 (null 방지)
          _isLoading = false;
        });
      } else {
        print('Error fetching scores: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LeaderBoard'), backgroundColor: Colors.cyan),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())  // 로딩 중일 때
          : ListView.builder(
        itemCount: _scoreList.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text('Player ${index + 1}'),
            subtitle: Text('Total Score: ${_calculateTotalScore(_scoreList[index])}'),  // 점수 표시
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // 클릭 시 점수표 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScoreDetailsScreen(
                    playerData: _scoreList[index],  // 클릭한 플레이어의 데이터 전달
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchScores,  // 새로고침 버튼을 누르면 점수 목록을 다시 가져옴
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.cyan,
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MenuBottom(),
    );
  }

  // 총 점수 계산 함수
  int _calculateTotalScore(dynamic playerData) {
    final List<dynamic> scores = playerData['score'];
    // 모든 점수를 정수로 변환 후 합산
    return scores.fold<int>(0, (sum, s) => sum + (int.tryParse(s.toString()) ?? 0));
  }
}

// 클릭 시 나오는 점수표 화면
class ScoreDetailsScreen extends StatelessWidget {
  final dynamic playerData;  // 플레이어 데이터

  const ScoreDetailsScreen({required this.playerData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Score Details'), backgroundColor: Colors.cyan),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Player Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildScoreTable(playerData),  // 점수 세부 항목 표 생성
          ],
        ),
      ),
    );
  }

  // 점수표를 동적으로 생성하는 함수 (3줄: Hole, Score, Par)
  Widget _buildScoreTable(dynamic playerData) {
    final List<dynamic> holes = playerData['hole'];
    final List<dynamic> scores = playerData['score'];
    final List<dynamic> pars = playerData['par'];

    if (holes.isEmpty || scores.isEmpty || pars.isEmpty) {
      return const Text('No details available', style: TextStyle(fontSize: 16));
    }

    return Table(
      border: TableBorder.all(color: Colors.black),  // 테두리 추가
      columnWidths: const <int, TableColumnWidth>{
        0: FixedColumnWidth(100),  // Hole 열의 너비
        1: FixedColumnWidth(100),  // Score 열의 너비
        2: FixedColumnWidth(100),  // Par 열의 너비
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.cyan),  // 제목 행 배경색
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Hole', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Par', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        for (int i = 0; i < holes.length; i++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(holes[i].toString()),  // 홀 번호
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(scores[i].toString()),  // 점수
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(pars[i].toString()),  // 파
              ),
            ],
          ),
      ],
    );
  }
}
