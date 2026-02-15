import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'player_waiting_screen.dart';

class PlayerRegisterScreen extends StatefulWidget {
  final String roomId;
  
  const PlayerRegisterScreen({super.key, required this.roomId});

  @override
  State<PlayerRegisterScreen> createState() => _PlayerRegisterScreenState();
}

class _PlayerRegisterScreenState extends State<PlayerRegisterScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  void _loadPlayers() {
    // リアルタイムでプレイヤー情報を監視
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
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'プレイヤーが登録されていません';
            _isLoading = false;
          });
        }
      }
    });
  }

Future<void> _selectPlayer(Map<String, dynamic> player) async {
    if (player['connected'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('この名前はすでに選択されています'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final ref = FirebaseDatabase.instance
          .ref('rooms/${widget.roomId}/players/${player['id']}');
      
      final snapshot = await ref.get();
      final currentData = Map<String, dynamic>.from(snapshot.value as Map);
      
      if (currentData['connected'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('この名前は他のプレイヤーに選択されました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      await ref.update({'connected': true});
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerWaitingScreen(
              roomId: widget.roomId,
              playerId: player['id'],
            ),
          ),
        );
      }
    } catch (e) {
      print('Select player error: $e');
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '参加者選択',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ルームID: ${widget.roomId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      const Text(
                        'あなたの名前を選択してください',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      // プレイヤーリスト
                      ..._players.map((player) {
                        final isConnected = player['connected'] == true;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isConnected ? Colors.grey[200] : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: isConnected ? null : () => _selectPlayer(player),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isConnected ? Colors.grey : const Color(0xFF667eea),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _hexToColor(player['teamColor']),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        player['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isConnected ? Colors.grey : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (isConnected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4ecdc4),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '選択済',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                    
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('戻る'),
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