import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../services/multiplayer_service.dart';
import 'online_battle_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({Key? key}) : super(key: key);

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  String playerName = 'جنگجو';
  String userId = '';

  List<dynamic> activePlayers = []; // 📡 لیست اهداف روی رادار
  bool isWaitingForResponse = false; // آیا منتظر جواب حریف هستیم؟

  @override
  void initState() {
    super.initState();
    _initRadar();
  }

  Future<void> _initRadar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      playerName = prefs.getString('playerName') ?? 'جنگجو';
      userId =
          prefs.getString('userId') ??
          'user_${DateTime.now().millisecondsSinceEpoch}';
      prefs.setString('userId', userId);
    });

    // ۱. روشن کردن رادار و اتصال به پایگاه
    MultiplayerService.instance.connectToLobby(userId, playerName);

    // ۲. دریافت زنده لیست اهداف
    MultiplayerService.instance.onLobbyUpdate = (players) {
      if (!mounted) return;
      setState(() {
        // خودمان را از لیست اهداف حذف می‌کنیم (تا به خودمان شلیک نکنیم!)
        activePlayers = players.where((p) => p['id'] != userId).toList();
      });
    };

    // ۳. دریافت اخطار نبرد از سمت دیگران
    MultiplayerService.instance.onIncomingChallenge = (challengeData) {
      if (!mounted) return;
      _showIncomingChallengeDialog(challengeData);
    };

    // ۴. حریف از نبرد ترسید و رد کرد
    MultiplayerService.instance.onChallengeRejected = (reason) {
      if (!mounted) return;
      setState(() => isWaitingForResponse = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🏃 $reason',
            style: const TextStyle(fontFamily: 'Piramooz'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    };

    // ۵. نبرد قبول شد! پرتاب به میدان
    MultiplayerService.instance.onMatchFound = (matchId, opponentData) {
      if (!mounted) return;

      // بستن هرگونه دیالوگ باز
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst || route.settings.name == '/lobby');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineBattleScreen(
            matchId: matchId,
            opponentData: opponentData,
            myName: playerName,
          ),
        ),
      );
    };
  }

  // 🎯 ارسال درخواست نبرد
  void _sendChallenge(String targetSocketId, String targetName) {
    setState(() => isWaitingForResponse = true);
    MultiplayerService.instance.sendChallenge(targetSocketId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'درخواست نبرد برای [$targetName] ارسال شد...',
          style: const TextStyle(fontFamily: 'Piramooz'),
        ),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🚨 نمایش آژیر حمله (کسی به ما درخواست داده)
  void _showIncomingChallengeDialog(Map<String, dynamic> challengeData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: const Text(
          '🚨 اخطار نبرد! 🚨',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Piramooz', color: Colors.redAccent),
        ),
        content: Text(
          'فرمانده [ ${challengeData['challengerName']} ] شما را به مبارزه طلبیده است!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Piramooz',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade800,
            ),
            onPressed: () {
              Navigator.pop(context);
              MultiplayerService.instance.respondToChallenge(
                challengeData['challengerSocketId'],
                false,
              );
            },
            child: const Text(
              'رد کردن',
              style: TextStyle(fontFamily: 'Piramooz', color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            onPressed: () {
              // فقط پیام قبول رو می‌فرستیم، سرور خودش ما رو می‌بره تو بازی
              MultiplayerService.instance.respondToChallenge(
                challengeData['challengerSocketId'],
                true,
              );
            },
            child: const Text(
              '⚔️ قبول نبرد',
              style: TextStyle(fontFamily: 'Piramooz', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'رادار مرکزی 🌍',
          style: TextStyle(
            fontFamily: 'Piramooz',
            color: AppColors.epicGold,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.epicGold),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isWaitingForResponse ? _buildWaitingState() : _buildRadarList(),
    );
  }

  Widget _buildWaitingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.epicGold),
          SizedBox(height: 20),
          Text(
            'در حال انتظار برای پاسخ حریف...',
            style: TextStyle(
              fontFamily: 'Piramooz',
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarList() {
    if (activePlayers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar, color: Colors.greenAccent, size: 80),
            SizedBox(height: 20),
            Text(
              'در حال اسکن پایگاه داده...\nفعلاً کسی در رادار نیست.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Piramooz',
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activePlayers.length,
      itemBuilder: (context, index) {
        final player = activePlayers[index];
        return Card(
          color: Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              player['name'],
              style: const TextStyle(
                fontFamily: 'Piramooz',
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bloodRed,
              ),
              onPressed: () =>
                  _sendChallenge(player['socketId'], player['name']),
              child: const Text(
                '⚔️ نبرد',
                style: TextStyle(fontFamily: 'Piramooz', color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
