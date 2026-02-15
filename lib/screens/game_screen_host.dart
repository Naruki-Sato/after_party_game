import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class GameScreenHost extends StatefulWidget {
  final String roomId;
  
  const GameScreenHost({super.key, required this.roomId});

  @override
  State<GameScreenHost> createState() => _GameScreenHostState();
}

class _GameScreenHostState extends State<GameScreenHost> {
  Map<String, dynamic>? _roomData;
  int _timeLeft = 0;
  Timer? _timer;
  bool _showTheme = true;
  bool _showStart = false;
  bool _gameStarted = false;

  @override
  void initState() {
    super.initState();
    _loadRoomData();
    _startThemeAnimation();
  }

  void _startThemeAnimation() {
    // 2秒間お題表示
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showTheme = false;
          _showStart = true;
        });
      }
    });

    // さらに1秒後にSTART表示を消してゲーム開始
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showStart = false;
          _gameStarted = true;
        });
        _startTimer();
      }
    });
  }

  void _loadRoomData() {
    final ref = FirebaseDatabase.instance.ref('rooms/${widget.roomId}');
    
    ref.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        if (mounted) {
          setState(() {
            _roomData = data;
          });
        }
      }
    });
  }

  void _startTimer() {
    if (_roomData == null) return;
    
    final timeLimit = _roomData!['timeLimit'] ?? 30;
    setState(() {
      _timeLeft = timeLimit;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _endGame() {
    // 結果画面に遷移する処理（後で実装）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ゲーム終了！')),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showTheme) {
      return _buildThemeScreen();
    }
    
    if (_showStart) {
      return _buildStartScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildThemeScreen() {
    final themeChar = _roomData?['theme']?['char'] ?? '';
    final themeDetail = _roomData?['theme']?['detail'] ?? '';
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2c3e50),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'お題',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '「$themeChar」から始まる',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                themeDetail,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2c3e50),
        ),
        child: const Center(
          child: Text(
            'START!!',
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildGameScreen() {
    if (_roomData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final numTeams = _roomData!['numTeams'] ?? 4;
    final teamsData = _roomData!['teams'];
    final themeChar = _roomData!['theme']?['char'] ?? '';
    final themeDetail = _roomData!['theme']?['detail'] ?? '';
    
    if (teamsData == null || teamsData is! Map) {
      return Scaffold(
        body: Container(
          color: const Color(0xFF2c3e50),
          child: const Center(
            child: Text(
              'チームデータを読み込み中...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }
    
    // teamsDataのキーをすべて文字列として取得
    print('Teams data keys: ${teamsData.keys}');
    print('Teams data: $teamsData');
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2c3e50),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF34495e),
                child: Column(
                  children: [
                    Text(
                      '⏱️ $_timeLeft秒',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$themeChar - $themeDetail',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // チームボックス
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: numTeams > 3 ? 2 : numTeams,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: numTeams,
                  itemBuilder: (context, index) {
                    final teamIdStr = index.toString();  // ← 文字列に変換
                    print('Looking for team: $teamIdStr');
                    
                    final teamDataRaw = teamsData[teamIdStr];  // ← 文字列を使用
                    
                    if (teamDataRaw == null) {
                      print('Team $teamIdStr not found');
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'チーム${index + 1}\n読み込み中',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    
                    final team = Map<String, dynamic>.from(teamDataRaw as Map);
                    final teamName = team['name'] ?? 'チーム${index + 1}';
                    final blocksData = team['blocks'];
                    final blocks = blocksData != null 
                        ? List<Map<String, dynamic>>.from(
                            (blocksData as List).map((e) => Map<String, dynamic>.from(e as Map))
                          )
                        : <Map<String, dynamic>>[];
                    final height = team['height'] ?? 0;
                    
                    return _buildTeamBox(teamName, blocks, height, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBox(String teamName, List<Map<String, dynamic>> blocks, int height, int teamIndex) {
    final colors = [
      const Color(0xFFff6b6b),
      const Color(0xFF4ecdc4),
      const Color(0xFFffe66d),
      const Color(0xFFa8e6cf),
      const Color(0xFFff8c94),
      const Color(0xFFa8dadc),
    ];
    
    final teamColor = colors[teamIndex % colors.length];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: teamColor, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // チーム名
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              teamName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // ブロック表示エリア
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: blocks.map((block) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: teamColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      block['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // 高さ表示
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              '$height段',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}