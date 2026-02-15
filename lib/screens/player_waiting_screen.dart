import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'game_screen_player.dart';  // ← この行を追加
import 'player_register_screen.dart';

class PlayerWaitingScreen extends StatefulWidget {
  final String roomId;
  final String playerId;
  
  const PlayerWaitingScreen({
    super.key,
    required this.roomId,
    required this.playerId,
  });

  @override
  State<PlayerWaitingScreen> createState() => _PlayerWaitingScreenState();
}

class _PlayerWaitingScreenState extends State<PlayerWaitingScreen> {
  Map<String, dynamic>? _playerInfo;
  String _teamName = '';

  @override
  void initState() {
    super.initState();
    _loadPlayerInfo();
  }

  void _loadPlayerInfo() {
    // プレイヤー情報を監視
    final playerRef = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/players/${widget.playerId}');
    
    playerRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        if (mounted) {
          setState(() {
            _playerInfo = data;
            _teamName = 'チーム${(data['team'] ?? 0) + 1}';
          });
        }
      }
    });
    
    // ゲーム状態を監視
    final roomRef = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/gameState');
    
    roomRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value == 'playing') {
        if (mounted) {
          // ゲーム画面に遷移
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreenPlayer(
                roomId: widget.roomId,
                playerId: widget.playerId,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _handleBack() async {
    // プレイヤーの接続状態をfalseに戻す
    try {
      final ref = FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/players/${widget.playerId}');
      
      await ref.update({'connected': false});
      
      if (mounted) {
        // 参加者選択画面に戻る
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerRegisterScreen(roomId: widget.roomId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        size: 64,
                        color: Color(0xFF667eea),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ホストが開始するまで\nお待ちください',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      if (_playerInfo != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _hexToColor(_playerInfo!['teamColor'] ?? '#ff6b6b'),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _playerInfo!['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _teamName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'ゲームのルール',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildRuleItem('📝', 'お題に合った単語を入力しよう'),
                            _buildRuleItem('📦', '単語がブロックになって積み上がる'),
                            _buildRuleItem('🏆', '制限時間内に最も高く積んだチームが勝利'),
                            _buildRuleItem('⚡', '短すぎる単語や長すぎる単語には注意'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleBack,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('戻る'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}