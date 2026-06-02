import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../services/api_service.dart'; // آدرس فایل api_service خودت رو چک کن

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String playerName = 'جنگجو';
  String playerAvatar = '🛡️';
  int totalCoins = 0;

  bool isLoading = true;
  List<dynamic> topPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadDataAndSync();
  }

  Future<void> _loadDataAndSync() async {
    final prefs = await SharedPreferences.getInstance();

    playerName = prefs.getString('playerName') ?? 'جنگجو';
    playerAvatar = prefs.getString('playerAvatar') ?? '🛡️';
    totalCoins = prefs.getInt('totalCoins') ?? 100;

    // اول امتیاز کاربر فعلی رو به سرور می‌فرستیم تا آپدیت بشه
    await ApiService.updateScore(playerName, playerAvatar, totalCoins);

    // حالا لیست جدید رو از سرور می‌گیریم
    final players = await ApiService.getTopPlayers();

    if (mounted) {
      setState(() {
        topPlayers = players;
        isLoading = false;
      });
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // طلا
    if (rank == 2) return const Color(0xFFC0C0C0); // نقره
    if (rank == 3) return const Color(0xFFCD7F32); // برنز
    return Colors.grey.shade600; // بقیه
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'تالار افتخارات 🏆',
          style: TextStyle(
            fontFamily: 'Piramooz',
            color: AppColors.epicGold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.epicGold),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141414), Color(0xFF2A2A2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.public, color: Colors.blueAccent, size: 60),
            const SizedBox(height: 10),
            const Text(
              'برترین جنگجویان آنلاین',
              style: TextStyle(
                fontFamily: 'Piramooz',
                color: AppColors.epicGold,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // لیست نفرات برتر از سرور
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.epicGold,
                      ),
                    )
                  : topPlayers.isEmpty
                  ? const Center(
                      child: Text(
                        'هنوز کسی ثبت نشده!',
                        style: TextStyle(
                          fontFamily: 'Piramooz',
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: topPlayers.length,
                      itemBuilder: (context, index) {
                        final player = topPlayers[index];
                        final rankColor = _getRankColor(player['rank']);

                        // چک میکنیم آیا این ردیف متعلق به خود کاربره؟
                        final isMe = player['name'] == playerName;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.bloodRed.withOpacity(0.8)
                                : Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: rankColor,
                              width: isMe ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: rankColor.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${player['rank']}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Piramooz',
                                    fontSize: 24,
                                    color: rankColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                player['avatar'],
                                style: const TextStyle(fontSize: 35),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  player['name'] + (isMe ? ' (شما)' : ''),
                                  style: const TextStyle(
                                    fontFamily: 'Piramooz',
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${player['score']}',
                                    style: const TextStyle(
                                      fontFamily: 'Piramooz',
                                      fontSize: 20,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
