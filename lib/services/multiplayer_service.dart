import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:developer' as developer;

class MultiplayerService {
  MultiplayerService._privateConstructor();
  static final MultiplayerService instance =
      MultiplayerService._privateConstructor();

  IO.Socket? socket;

  // 📡 گیرنده‌های جدید رادار
  Function(List<dynamic> players)? onLobbyUpdate;
  Function(Map<String, dynamic> challengeData)? onIncomingChallenge;
  Function(String reason)? onChallengeRejected;
  Function(String matchId, Map<String, dynamic> opponentData)? onMatchFound;

  // ورود به لابی باز
  void connectToLobby(String userId, String userName) {
    if (socket != null && socket!.connected) return;

    // ⚠️ لینک لیارای خودت رو اینجا بگذار
    String serverUrl = 'https://astoniea-server.liara.run';

    developer.log('در حال اتصال به رادار جهانی...', name: 'Multiplayer');

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      developer.log(
        '🟢 اتصال به سرور برقرار شد! اعلام حضور در رادار...',
        name: 'Multiplayer',
      );
      socket!.emit('join_lobby', {'id': userId, 'name': userName});
    });

    // 🗺️ دریافت زنده لیست بازیکنان حاضر
    socket!.on('lobby_update', (data) {
      if (onLobbyUpdate != null) onLobbyUpdate!(data);
    });

    // ⚔️ کسی ما را به نبرد دعوت کرده!
    socket!.on('incoming_challenge', (data) {
      developer.log('🚨 اخطار نبرد دریافت شد: $data', name: 'Multiplayer');
      if (onIncomingChallenge != null) onIncomingChallenge!(data);
    });

    // 🏃 حریف ترسید و رد کرد
    socket!.on('challenge_rejected', (data) {
      if (onChallengeRejected != null) onChallengeRejected!(data['reason']);
    });

    // 💥 نبرد قبول شد، پرتاب به میدان نبرد
    socket!.on('match_found', (data) {
      final isPlayer1 = data['player1']['socketId'] == socket!.id;
      final opponent = isPlayer1 ? data['player2'] : data['player1'];
      if (onMatchFound != null) {
        onMatchFound!(data['matchId'], {
          'id': opponent['id'],
          'name': opponent['name'],
          'socketId': opponent['socketId'],
        });
      }
    });
  }

  // 🎯 ارسال درخواست نبرد به یک شخص
  void sendChallenge(String targetSocketId) {
    developer.log('ارسال چالش به: $targetSocketId', name: 'Multiplayer');
    socket!.emit('send_challenge', {'targetSocketId': targetSocketId});
  }

  // 👍 👎 جواب دادن به درخواست دیگران
  void respondToChallenge(String challengerSocketId, bool accepted) {
    socket!.emit('challenge_response', {
      'challengerSocketId': challengerSocketId,
      'accepted': accepted,
    });
  }
}
