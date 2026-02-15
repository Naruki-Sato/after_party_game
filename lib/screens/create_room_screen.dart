import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import 'host_waiting_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  final String? savedRoomId;
  const CreateRoomScreen({super.key, this.savedRoomId});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final List<TextEditingController> _participantControllers = [TextEditingController()];
  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _themeDetailController = TextEditingController();
  
  int _timeLimit = 30;
  int _numTeams = 4;
  List<String> _teamNames = ['チーム1', 'チーム2', 'チーム3', 'チーム4'];
  
  final Map<String, bool> _optionRules = {
    'oneCharBreak': true,
    'twoCharThree': true,
    'threeCharThree': true,
    'longWordHeight': true,
  };
  
  bool _isCreating = false;
  void initState() {
    super.initState();
    if (widget.savedRoomId != null) {
      // ルームIDが保存されている場合の処理（将来の拡張用）
    }
  }
  bool _isHiragana(String char) {
    if (char.isEmpty || char.length != 1) return false;
    final code = char.codeUnitAt(0);
    return code >= 0x3040 && code <= 0x309F;
  }

  Future<void> _createRoom() async {
    if (_isCreating) return;
    
    final participants = _participantControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    
    if (participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('参加者を入力してください')),
      );
      return;
    }
    
    if (_themeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お題の文字を入力してください')),
      );
      return;
    }
    
    if (!_isHiragana(_themeController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お題はひらがな1文字で入力してください')),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    
    try {
      final gameService = context.read<GameService>();
      final roomId = await gameService.createRoom(
        participants: participants,
        theme: _themeController.text,
        themeDetail: _themeDetailController.text,
        timeLimit: _timeLimit,
        optionRules: _optionRules,
        numTeams: _numTeams,
        teamNames: _teamNames,
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HostWaitingScreen(
              roomId: roomId,
              onBack: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateRoomScreen(savedRoomId: roomId),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ルーム作成に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'ルーム作成',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // 参加者
                    const Text('参加者', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._participantControllers.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  hintText: '参加者 ${entry.key + 1}',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            if (_participantControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _participantControllers.removeAt(entry.key);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _participantControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('参加者を追加'),
                    ),
                    const SizedBox(height: 16),
                    
                    // チーム数
                    const Text('チーム数', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [2, 3, 4, 5, 6].map((num) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _numTeams = num;
                                  while (_teamNames.length < num) {
                                    _teamNames.add('チーム${_teamNames.length + 1}');
                                  }
                                  _teamNames = _teamNames.sublist(0, num);
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _numTeams == num
                                    ? const Color(0xFF667eea)
                                    : Colors.grey[300],
                                foregroundColor: _numTeams == num
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              child: Text('$num'),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // お題
                    const Text('お題', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _themeController,
                            maxLength: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'あ',
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('から始まる'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _themeDetailController,
                            decoration: InputDecoration(
                              hintText: '〜なもの',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // 制限時間
                    Text('制限時間: $_timeLimit秒', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _timeLimit.toDouble(),
                      min: 10,
                      max: 60,
                      divisions: 50,
                      onChanged: (value) {
                        setState(() => _timeLimit = value.toInt());
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // オプションルール
                    const Text('オプションルール', 
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('1文字ブロックは即破壊'),
                      value: _optionRules['oneCharBreak'],
                      onChanged: (value) {
                        setState(() => _optionRules['oneCharBreak'] = value!);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('2文字連続3回で破壊'),
                      value: _optionRules['twoCharThree'],
                      onChanged: (value) {
                        setState(() => _optionRules['twoCharThree'] = value!);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('3文字連続3回で破壊'),
                      value: _optionRules['threeCharThree'],
                      onChanged: (value) {
                        setState(() => _optionRules['threeCharThree'] = value!);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('長単語は高さ変化'),
                      value: _optionRules['longWordHeight'],
                      onChanged: (value) {
                        setState(() => _optionRules['longWordHeight'] = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // ボタン
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('戻る'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isCreating ? null : _createRoom,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFff6b6b),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_isCreating ? '作成中...' : 'ルーム作成'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _participantControllers) {
      controller.dispose();
    }
    _themeController.dispose();
    _themeDetailController.dispose();
    super.dispose();
  }
}
