import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class GameScreenPlayer extends StatefulWidget {
  final String roomId;
  final String playerId;
  
  const GameScreenPlayer({
    super.key,
    required this.roomId,
    required this.playerId,
  });

  @override
  State<GameScreenPlayer> createState() => _GameScreenPlayerState();
}

class _GameScreenPlayerState extends State<GameScreenPlayer> {
  Map<String, dynamic>? _roomData;
  Map<String, dynamic>? _playerInfo;
  int _timeLeft = 0;
  Timer? _timer;
  bool _showTheme = true;
  bool _showStart = false;
  bool _gameStarted = false;
  
  final TextEditingController _wordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _startThemeAnimation();
  }

  void _startThemeAnimation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showTheme = false;
          _showStart = true;
        });
      }
    });

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

  void _loadData() {
    final roomRef = FirebaseDatabase.instance.ref('rooms/${widget.roomId}');
    roomRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _roomData = data;
          });
        }
      }
    });

    final playerRef = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/players/${widget.playerId}');
    playerRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (mounted) {
          setState(() {
            _playerInfo = data;
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
      }
    });
  }

  Future<void> _submitWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty || _playerInfo == null || _roomData == null) return;

    final themeChar = _roomData!['theme']?['char'] ?? '';
    if (!word.startsWith(themeChar)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「$themeChar」から始まる単語を入力してください')),
      );
      return;
    }

    try {
      var teamId = _playerInfo!['team'];
      String teamIdStr = teamId is int ? teamId.toString() : teamId.toString();
      
      print('Submitting word for team: $teamIdStr');
      
      final teamRef = FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/teams/$teamIdStr');
      
      final snapshot = await teamRef.get();
      final teamData = snapshot.exists 
          ? Map<String, dynamic>.from(snapshot.value as Map)
          : {};
      
      final blocksData = teamData['blocks'];
      final blocks = blocksData != null
          ? List<Map<String, dynamic>>.from(
              (blocksData as List).map((e) => Map<String, dynamic>.from(e as Map))
            )
          : <Map<String, dynamic>>[];
      
      final usedWordsData = teamData['usedWords'];
      final usedWords = usedWordsData != null
          ? List<String>.from(usedWordsData as List)
          : <String>[];
      
      if (usedWords.contains(word)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('既に使用された単語です')),
        );
        _wordController.clear();
        return;
      }
      
      final newBlock = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'text': word,
        'height': 1,
        'color': _playerInfo!['teamColor'],
        'width': (30 + word.length * 10).clamp(0, 100),
      };
      
      blocks.add(newBlock);
      usedWords.add(word);
      
      await teamRef.update({
        'blocks': blocks,
        'height': (teamData['height'] ?? 0) + 1,
        'usedWords': usedWords,
      });
      
      _wordController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('送信しました！'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      print('Submit word error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wordController.dispose();
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
                style: TextStyle(fontSize: 24, color: Colors.white70),
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
    if (_playerInfo == null || _roomData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    var teamId = _playerInfo!['team'];
    String teamIdStr = teamId is int ? teamId.toString() : teamId.toString();
    
    print('Player team ID: $teamId (type: ${teamId.runtimeType})');
    print('Team ID string: $teamIdStr');
    
    final teamsData = _roomData!['teams'];
    
    if (teamsData == null) {
      return const Scaffold(
        body: Center(child: Text('チームデータがありません', style: TextStyle(color: Colors.white))),
      );
    }
    
    print('Teams data type: ${teamsData.runtimeType}');
    print('Teams data: $teamsData');
    
    Map<String, dynamic> teamDataRaw;
    if (teamsData is List) {
      print('Teams is List, converting...');
      if (teamId is int && teamId < teamsData.length) {
        teamDataRaw = Map<String, dynamic>.from(teamsData[teamId] as Map);
      } else {
        return Scaffold(
          body: Container(
            color: const Color(0xFF2c3e50),
            child: Center(
              child: Text(
                'チームデータが見つかりません (List)\nteamId: $teamId',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    } else if (teamsData is Map) {
      print('Teams is Map, keys: ${teamsData.keys}');
      final rawData = teamsData[teamIdStr];
      if (rawData == null) {
        return Scaffold(
          body: Container(
            color: const Color(0xFF2c3e50),
            child: Center(
              child: Text(
                'チームデータが見つかりません (Map)\nteamId: $teamIdStr\nkeys: ${teamsData.keys}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      teamDataRaw = Map<String, dynamic>.from(rawData as Map);
    } else {
      return Scaffold(
        body: Container(
          color: const Color(0xFF2c3e50),
          child: Center(
            child: Text(
              'チームデータの型が不正: ${teamsData.runtimeType}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
    
    final blocksData = teamDataRaw['blocks'];
    final blocks = blocksData != null
        ? List<Map<String, dynamic>>.from(
            (blocksData as List).map((e) => Map<String, dynamic>.from(e as Map))
          )
        : <Map<String, dynamic>>[];
    final height = teamDataRaw['height'] ?? 0;
    final teamName = teamDataRaw['name'] ?? 'チーム${teamId + 1}';
    final themeChar = _roomData!['theme']?['char'] ?? '';
    final themeDetail = _roomData!['theme']?['detail'] ?? '';
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2c3e50),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0xFF34495e),
                child: Column(
                  children: [
                    Text(
                      '⏱️ $_timeLeft秒',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$themeChar - $themeDetail',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_playerInfo!['name']} ($teamName)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: _hexToColor(_playerInfo!['teamColor']),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          teamName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            reverse: true,
                            child: Column(
                              children: blocks.map<Widget>((block) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: _hexToColor(_playerInfo!['teamColor']),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    block['text'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Text(
                          '$height段',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0xFF34495e),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _wordController,
                        enabled: _timeLeft > 0,
                        style: const TextStyle(fontSize: 15, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: '「$themeChar」から始まる単語',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _submitWord(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _timeLeft > 0 ? _submitWord : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFff6b6b),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      ),
                      child: const Text('送信'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}