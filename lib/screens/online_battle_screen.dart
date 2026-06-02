import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/multiplayer_service.dart';

class OnlineBattleScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> opponentData;
  final String myName;

  const OnlineBattleScreen({
    Key? key,
    required this.matchId,
    required this.opponentData,
    required this.myName,
  }) : super(key: key);

  @override
  // ⚙️ اضافه شدن SingleTickerProviderStateMixin برای روشن شدن موتور تایمر
  State<OnlineBattleScreen> createState() => _OnlineBattleScreenState();
}

class _OnlineBattleScreenState extends State<OnlineBattleScreen>
    with SingleTickerProviderStateMixin {
  String questionText = 'در حال ارتباط با پایگاه فرماندهی...';
  List<dynamic> options = [];
  int myScore = 0;
  int opponentScore = 0;
  bool hasAnswered = false;

  String? resultMessage;
  Map<String, dynamic>? finalSummary; // 📋 ذخیره صورت‌جلسه نهایی نبرد

  // ⏱️ متغیرهای مربوط به بمب ساعتی
  late AnimationController _timerController;
  int _timeLimit = 10;

  @override
  void initState() {
    super.initState();

    // ⚙️ استارت موتور تایمر گرافیکی
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timeLimit),
    );

    _setupSocketListeners();
  }

  @override
  void dispose() {
    _timerController.dispose(); // خاموش کردن موتور هنگام خروج
    super.dispose();
  }

  // 🧠 منطق استاندارد جهانی: فقط گوش دادن به دستورات داور (سرور)
  void _setupSocketListeners() {
    final socket = MultiplayerService.instance.socket;

    // ۱. دریافت سوال جدید
    socket?.on('new_question', (data) {
      if (!mounted) return;
      setState(() {
        questionText = data['question'];
        options = data['options'];
        hasAnswered = false; // خشاب‌ها برای سوال جدید پر می‌شود
        resultMessage = null;
        finalSummary = null;

        // ⏱️ تنظیم و اجرای نوار زمان
        _timeLimit = data['timeLimit'] ?? 10;
        _timerController.duration = Duration(seconds: _timeLimit);
        _timerController.reverse(from: 1.0); // حرکت نوار از پر به خالی
      });
    });

    // ۲. آپدیت زنده امتیازها بعد از جواب دادن
    socket?.on('score_update', (data) {
      if (!mounted) return;
      setState(() {
        myScore = data['scores'][socket.id] ?? myScore;
        opponentScore =
            data['scores'][widget.opponentData['id']] ?? opponentScore;
      });
    });

    // ۳. اعلام پیروز نبرد (همراه با جزئیات کامل)
    socket?.on('match_over', (data) {
      if (!mounted) return;
      _timerController.stop(); // توقف زمان‌سنج

      setState(() {
        finalSummary = data; // ذخیره کل اطلاعات
        resultMessage = _calculateResultText(data); // محاسبه متن حماسی
        questionText = 'پایان نبرد';
        options = [];
      });
    });

    // ۴. فرار حریف از میدان
    socket?.on('opponent_disconnected', (_) {
      if (!mounted) return;
      _timerController.stop(); // توقف زمان‌سنج

      setState(() {
        resultMessage = '🏃 حریف از ترس فرار کرد! شما برنده شدید.';
        questionText = 'عملیات لغو شد';
        options = [];
        // ساخت یک صورت‌جلسه اضطراری تا دکمه بازگشت نمایش داده شود
        finalSummary = {
          'player1': {'name': widget.myName, 'score': myScore},
          'player2': {
            'name': widget.opponentData['name'],
            'score': opponentScore,
          },
        };
      });
    });
  }

  // ⚖️ محاسبه دقیق متن پیروزی یا شکست
  String _calculateResultText(Map<String, dynamic> data) {
    final socketId = MultiplayerService.instance.socket?.id;
    if (data['result'] == "DRAW") return "🤝 نبرد مساوی شد!";

    bool iAmWinner = data['winnerId'] == socketId;
    return iAmWinner ? "🏆 پیروز میدان شدی!" : "💀 شکست خوردی...";
  }

  // 🔫 شلیکِ جواب به سمت سرور
  void _submitAnswer(int index) {
    if (hasAnswered) return; // جلوگیری از اسپم

    setState(() {
      hasAnswered = true;
    });

    MultiplayerService.instance.socket?.emit('submit_answer', {
      'matchId': widget.matchId,
      'answerIndex': index,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ==========================================
              // 📊 بخش بالای صفحه: تابلوی امتیازات زنده (HUD)
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerCard(widget.myName, myScore, Colors.blueAccent),
                  const Text('⚔️', style: TextStyle(fontSize: 32)),
                  _buildPlayerCard(
                    widget.opponentData['name'],
                    opponentScore,
                    Colors.redAccent,
                  ),
                ],
              ),

              const Spacer(),

              // ==========================================
              // 🧠 بخش میانی: نمایشگر سوال یا تابلوی نتایج نهایی
              // ==========================================
              if (finalSummary != null && resultMessage != null)
                // 🏆 تابلوی حماسی پایان بازی
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.epicGold, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        resultMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Piramooz',
                          fontSize: 32,
                          color: AppColors.epicGold,
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 30),

                      // نمایش جزئیات امتیازات هر دو بازیکن
                      _buildResultRow(
                        finalSummary!['player1']['name'],
                        finalSummary!['player1']['score'],
                        Colors.blueAccent,
                      ),
                      const SizedBox(height: 10),
                      _buildResultRow(
                        finalSummary!['player2']['name'],
                        finalSummary!['player2']['score'],
                        Colors.redAccent,
                      ),

                      const SizedBox(height: 30),

                      // 🔙 دکمه بازگشت به منوی اصلی
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            // بازگشت قدرتمند به اولین صفحه (منوی اصلی)
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          child: const Text(
                            'بازگشت به مقر فرماندهی 🏠',
                            style: TextStyle(
                              fontFamily: 'Piramooz',
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // ❓ کادر نمایش سوالات در حین نبرد
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.epicGold, width: 2),
                  ),
                  child: Text(
                    questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Piramooz',
                      fontSize: 24,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),

              const Spacer(),

              // ==========================================
              // ⏱️ نوار زمان (تایمر زنده)
              // ==========================================
              if (options.isNotEmpty && finalSummary == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: AnimatedBuilder(
                    animation: _timerController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _timerController.value,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade800,
                        // تغییر رنگ به قرمز در ۳ ثانیه آخر
                        color: _timerController.value > 0.3
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        borderRadius: BorderRadius.circular(5),
                      );
                    },
                  ),
                ),

              // ==========================================
              // 🕹️ بخش پایینی: دکمه‌های تاکتیکی (گزینه‌ها)
              // ==========================================
              if (options.isNotEmpty && finalSummary == null)
                ...List.generate(options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasAnswered
                              ? Colors.grey.shade800
                              : Colors.blueGrey.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        onPressed: () => _submitAnswer(index),
                        child: Text(
                          options[index],
                          style: TextStyle(
                            fontFamily: 'Piramooz',
                            fontSize: 18,
                            color: hasAnswered ? Colors.grey : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ویجت کمکی برای ساخت کارت‌های بالا (HUD)
  Widget _buildPlayerCard(String name, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Piramooz',
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontFamily: 'Piramooz',
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ویجت کمکی برای ردیف‌های تابلوی نتایج پایانی
  Widget _buildResultRow(String name, dynamic score, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Piramooz',
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        Text(
          '$score امتیاز',
          style: TextStyle(
            fontFamily: 'Piramooz',
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
