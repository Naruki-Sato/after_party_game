import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class GameService extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  String? roomId;
  String? playerId;
  bool isHost = false;
  Map<String, dynamic>? roomData;
  Map<String, dynamic>? savedRoomConfig;

  Future<String> createRoom({
    required List<String> participants,
    required String theme,
    required String themeDetail,
    required int timeLimit,
    required Map<String, bool> optionRules,
    required int numTeams,
    required List<String> teamNames,
  }) async {
    final newRoomId = (100000 + Random().nextInt(900000)).toString();
    final teamColors = ['#ff6b6b', '#4ecdc4', '#ffe66d', '#a8e6cf', '#ff8c94', '#a8dadc'];
    
    final playersData = <String, dynamic>{};
    for (var i = 0; i < participants.length; i++) {
      final teamIndex = i % numTeams;
      playersData['player_$i'] = {
        'name': participants[i],
        'team': teamIndex,
        'teamColor': teamColors[teamIndex],
        'connected': false,
      };
    }

    // キーを文字列として明示的に設定
    final teamsData = <String, dynamic>{};
    for (var i = 0; i < numTeams; i++) {
      teamsData['$i'] = {  // ← '$i' で文字列化
        'name': teamNames[i],
        'blocks': [],
        'height': 0,
        'twoCharStreak': [],
        'threeCharStreak': [],
        'usedWords': [],
      };
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final roomDataToSave = {
      'roomId': newRoomId,
      'players': playersData,
      'theme': {
        'char': theme,
        'detail': themeDetail,
      },
      'timeLimit': timeLimit,
      'optionRules': optionRules,
      'numTeams': numTeams,
      'teamNames': teamNames,
      'gameState': 'waiting',
      'teams': teamsData,
      'createdAt': now,
      'expiresAt': now + (2 * 60 * 60 * 1000),
    };

    print('Creating room with teams: ${teamsData.keys}');
    await _database.child('rooms').child(newRoomId).set(roomDataToSave);
    
    this.roomId = newRoomId;
    isHost = true;
    notifyListeners();
    
    return newRoomId;
  }

  Future<bool> joinRoom(String roomId) async {
    final snapshot = await _database.child('rooms').child(roomId).get();
    if (snapshot.exists) {
      this.roomId = roomId;
      isHost = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> registerPlayer(String playerId) async {
    this.playerId = playerId;
    await _database.child('rooms').child(roomId!).child('players').child(playerId).update({
      'connected': true,
    });
    notifyListeners();
  }

  void listenToRoom(Function(Map<String, dynamic>) onUpdate) {
    if (roomId == null) return;
    
    _database.child('rooms').child(roomId!).onValue.listen((event) {
      if (event.snapshot.exists) {
        roomData = Map<String, dynamic>.from(event.snapshot.value as Map);
        onUpdate(roomData!);
        notifyListeners();
      }
    });
  }

  Future<void> startGame() async {
    await _database.child('rooms').child(roomId!).update({
      'gameState': 'playing',
      'startTime': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> submitWord(String word, int teamId, String teamColor) async {
    final teamRef = _database.child('rooms').child(roomId!).child('teams').child('$teamId');
    final snapshot = await teamRef.get();
    final teamData = snapshot.exists ? Map<String, dynamic>.from(snapshot.value as Map) : {};
    
    final blocks = List<Map<String, dynamic>>.from(teamData['blocks'] ?? []);
    final usedWords = List<String>.from(teamData['usedWords'] ?? []);
    
    if (usedWords.contains(word)) return;
    
    final wordLength = word.length;
    int blockHeight = 1;
    
    if (roomData!['optionRules']['longWordHeight'] == true) {
      if (wordLength >= 5 && wordLength <= 8) {
        blockHeight = 2;
      } else if (wordLength >= 9) {
        blockHeight = 3;
      }
    }
    
    final newBlock = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'text': word,
      'height': blockHeight,
      'color': teamColor,
      'width': (30 + wordLength * 10).clamp(0, 100),
    };
    
    blocks.add(newBlock);
    usedWords.add(word);
    
    await teamRef.update({
      'blocks': blocks,
      'height': (teamData['height'] ?? 0) + blockHeight,
      'usedWords': usedWords,
    });
  }

  Future<void> playAgain() async {
    final teamsData = <String, dynamic>{};
    final numTeams = roomData!['numTeams'] as int;
    
    for (var i = 0; i < numTeams; i++) {
      teamsData['$i'] = {
        'name': roomData!['teams']['$i']['name'],
        'blocks': [],
        'height': 0,
        'twoCharStreak': [],
        'threeCharStreak': [],
        'usedWords': [],
      };
    }

    await _database.child('rooms').child(roomId!).update({
      'gameState': 'waiting',
      'teams': teamsData,
      'finalHeights': null,
    });
  }

  void reset() {
    roomId = null;
    playerId = null;
    isHost = false;
    roomData = null;
    savedRoomConfig = null;
    notifyListeners();
  }
}