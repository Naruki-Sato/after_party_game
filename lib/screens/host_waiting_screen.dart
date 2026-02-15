import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'create_room_screen.dart';
import 'game_screen_host.dart';

class HostWaitingScreen extends StatefulWidget {
  final String roomId;
  final VoidCallback? onBack;
  
  const HostWaitingScreen({super.key, required this.roomId, this.onBack});

  @override
  State<HostWaitingScreen> createState() => _HostWaitingScreenState();
}

class _HostWaitingScreenState extends State<HostWaitingScreen> {
  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();
    _listenToPlayers();
  }

  void _listenToPlayers() {
    final ref = FirebaseDatabase.instance
        .ref('rooms/${widget.roomId}/players');
    
    ref.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        final playersList = data.entries.map((entry) {
          final playerData = Map<String, dynamic>.from(entry.value as Map);
          return {
            'id': entry.key,
            'name': playerData['name'] ?? '名前なし',
            'team': playerData['team'] ?? 0,
            'teamColor': playerData['teamColor'] ?? '#ff6b6b',
            'connected': playerData['connected'] ?? false,
          };
        }).toList();
        
        if (mounted) {
          setState(() {
            _players = playersList;
          });
        }
      }
    });
  }

  Future<void> _startGame() async {
    try {
      final ref = FirebaseDatabase.instance.ref('rooms/${widget.roomId}');
      
      await ref.update({
        'gameState': 'playing',
        'startTime': DateTime.now().millisecondsSinceEpoch,
      });
      
      if (mounted) {
        // ゲーム画面に遷移
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreenHost(roomId: widget.roomId),
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
    final connectedCount = _players.where((p) => p['connected'] == true).length;
    
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'ホスト待機画面',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('ルームID', style: TextStyle(fontSize: 11)),
                          Text(
                            widget.roomId,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667eea),
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    QrImageView(
                      data: widget.roomId,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text('プレイヤーにこのIDまたはQRコードを共有してください'),
                    const SizedBox(height: 20),
                    
                    // プレイヤー一覧
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'プレイヤー一覧',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '$connectedCount/${_players.length}人参加中',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_players.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'プレイヤーが登録されていません',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ..._players.map((player) {
                              final isConnected = player['connected'] == true;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isConnected 
                                        ? const Color(0xFF4ecdc4) 
                                        : Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _hexToColor(player['teamColor']),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        player['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isConnected ? Colors.black : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isConnected 
                                            ? const Color(0xFF4ecdc4) 
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isConnected ? '✓ 参加済' : '未参加',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isConnected ? Colors.white : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onBack,
                            child: const Text('戻る'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: connectedCount > 0 ? _startGame : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFff6b6b),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                            ),
                            child: const Text('ゲーム開始'),
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
}