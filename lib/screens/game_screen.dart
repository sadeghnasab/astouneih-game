import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/word_model.dart';
import '../data/game_logic.dart';

bool isSfxEnabled = true;

class GameScreen extends StatefulWidget {
  // 👈 ورودی‌های جدید برای فهمیدن فصل و مرحله
  final int chapter;
  final int level;

  const GameScreen({
    Key? key,
    this.chapter = 1, // پیش‌فرض برای اینکه تو منو ارور نده
    this.level = 1,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  List<TatiWord> allWords = [];
  List<TatiWord> levelQuestions = []; // ۵ سوال مخصوص این مرحله
  TatiWord? currentQuestion;
  List<TatiWord> currentOptions = [];
  bool isLoading = true;

  // ----- سیستم جدید ۳ ستاره و ۵ سوال -----
  int currentQuestionIndex = 0; // از 0 تا 4
  int correctAnswersCount = 0; // تعداد جواب‌های درست

  int score = 0;
  int timePerQuestion = 15;

  int totalCoins = 0;
  int comboStreak = 0;
  bool is5050Used = false;
  bool isFreezeUsed = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _timerController;
  bool isAnswered = false;
  TatiWord? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _loadWallet();

    _timerController =
        AnimationController(
          vsync: this,
          duration: Duration(seconds: timePerQuestion),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && !isAnswered) {
            _handleTimeout();
          }
        });

    _loadData();
  }

  Future<void> _loadWallet() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalCoins = prefs.getInt('totalCoins') ?? 100;
      isSfxEnabled = prefs.getBool('isSfxEnabled') ?? true;
    });
  }

  Future<void> _updateWallet(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalCoins += amount;
    });
    await prefs.setInt('totalCoins', totalCoins);
  }

  @override
  void dispose() {
    _timerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound(String fileName) async {
    if (isSfxEnabled) {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    }
  }

  Future<void> _loadData() async {
    final String response = await rootBundle.loadString(
      'assets/data/tati_words.json',
    );
    final List<dynamic> data = json.decode(response);
    allWords = data.map((json) => TatiWord.fromJson(json)).toList();

    _generateQuestionsForLevel();
  }

  // 👈 منطق جدید استخراج دقیقاً ۵ سوال برای این مرحله
  void _generateQuestionsForLevel() {
    allWords.shuffle(Random()); // فعلاً رندوم می‌کنیم تا بانک سوالاتت کامل بشه

    // برداشتن ۵ سوال اول بعد از بُر زدن
    levelQuestions = allWords.take(5).toList();

    setState(() {
      currentQuestionIndex = 0;
      correctAnswersCount = 0;
      isLoading = false;
    });

    _loadCurrentQuestion();
  }

  void _loadCurrentQuestion() {
    currentQuestion = levelQuestions[currentQuestionIndex];
    currentOptions = GameLogic.generateQuestionOptions(
      allWords,
      currentQuestion!,
    );

    setState(() {
      isAnswered = false;
      selectedAnswer = null;
      is5050Used = false;
      isFreezeUsed = false;
    });

    _timerController.duration = Duration(seconds: timePerQuestion);
    _timerController.forward(from: 0.0);
  }

  void _handleTimeout() {
    setState(() {
      isAnswered = true;
      comboStreak = 0;
      _playSound('shield.mp3');
    });
    _showSnackBarMessage(false, 'زمان تمام شد! ⏳');
    _checkGameOverOrNext();
  }

  void _use5050() {
    if (isAnswered || is5050Used || currentOptions.length <= 2) return;
    if (totalCoins < 20) {
      _showSnackBarMessage(false, 'سکه کافی نیست!');
      return;
    }

    _updateWallet(-20);
    _playSound('sword.mp3');

    setState(() {
      is5050Used = true;
      List<TatiWord> wrongOptions = currentOptions
          .where((w) => w.id != currentQuestion!.id)
          .toList();
      wrongOptions.shuffle();
      currentOptions.remove(wrongOptions[0]);
      currentOptions.remove(wrongOptions[1]);
    });
  }

  void _useFreezeTime() {
    if (isAnswered || isFreezeUsed) return;
    if (totalCoins < 15) {
      _showSnackBarMessage(false, 'سکه کافی نیست!');
      return;
    }

    _updateWallet(-15);
    _playSound('sword.mp3');
    _timerController.stop();

    setState(() {
      isFreezeUsed = true;
    });

    _showSnackBarMessage(true, 'زمان منجمد شد! ❄️');

    Future.delayed(const Duration(seconds: 5), () {
      if (!isAnswered && mounted) {
        _timerController.forward();
      }
    });
  }

  void _checkAnswer(TatiWord selectedWord) {
    if (isAnswered) return;

    _timerController.stop();
    bool isCorrect = selectedWord.id == currentQuestion!.id;

    setState(() {
      isAnswered = true;
      selectedAnswer = selectedWord;

      if (isCorrect) {
        HapticFeedback.lightImpact();
        correctAnswersCount++; // 👈 ثبت جواب درست برای ستاره‌ها
        comboStreak += 1;

        int coinReward = 5;
        if (comboStreak >= 3) coinReward = 10;

        score += coinReward;
        _updateWallet(coinReward);
        _playSound('sword.mp3');

        _showSnackBarMessage(true, 'دقیق بود! (+$coinReward سکه)');
      } else {
        HapticFeedback.heavyImpact();
        comboStreak = 0;
        _playSound('shield.mp3');
        _showSnackBarMessage(false, 'غلط! جواب: ${currentQuestion!.tatiWord}');
      }
    });

    _checkGameOverOrNext();
  }

  void _checkGameOverOrNext() {
    Future.delayed(const Duration(seconds: 2), () {
      if (currentQuestionIndex < 4) {
        // هنوز ۵ سوال تموم نشده، برو سوال بعدی
        setState(() {
          currentQuestionIndex++;
        });
        _loadCurrentQuestion();
      } else {
        // ۵ سوال تموم شد! وقت حسابرسیه
        _showLevelCompleteDialog();
      }
    });
  }

  // 👈 پاپ‌آپ جدید و حماسیِ پایان مرحله (محاسبه ستاره‌ها)
  Future<void> _showLevelCompleteDialog() async {
    int stars = 0;
    if (correctAnswersCount == 3) stars = 1;
    if (correctAnswersCount == 4) stars = 2;
    if (correctAnswersCount == 5) stars = 3;

    bool isVictory = stars > 0;

    if (isVictory) {
      _playSound('sword.mp3'); // بعداً می‌تونی صدای پیروزی بذاری
      int bonusCoins = stars * 10;
      _updateWallet(bonusCoins);

      // ذخیره ستاره‌ها و باز کردن مرحله بعدی تو حافظه گوشی
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stars_c${widget.chapter}_l${widget.level}', stars);
      await prefs.setBool(
        'unlocked_c${widget.chapter}_l${widget.level + 1}',
        true,
      );
    } else {
      _playSound('gameover.mp3');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isVictory ? AppColors.epicGold : AppColors.bloodRed,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          isVictory ? 'عملیات موفقیت‌آمیز!' : 'عملیات شکست خورد!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isVictory ? AppColors.epicGold : AppColors.bloodRed,
            fontFamily: 'Piramooz',
            fontSize: 28,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'جواب‌های درست: $correctAnswersCount از ۵',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Piramooz',
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                );
              }),
            ),
            const SizedBox(height: 15),
            if (isVictory)
              Text(
                'پاداش فتح: +${stars * 10} سکه',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontFamily: 'Piramooz',
                ),
              )
            else
              const Text(
                'برای صعود باید حداقل ۳ جواب درست بدهید!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (isVictory)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                side: const BorderSide(color: AppColors.epicGold, width: 1.5),
              ),
              onPressed: () {
                Navigator.pop(context); // بستن دیالوگ
                Navigator.pop(context); // بازگشت به نقشه
                // 👈 اینجا بعداً دستور رفتن به مرحله بعد رو می‌نویسیم
              },
              child: const Text(
                'مرحله بعدی',
                style: TextStyle(fontFamily: 'Piramooz', color: Colors.white),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bloodRed,
                side: const BorderSide(color: AppColors.epicGold, width: 1.5),
              ),
              onPressed: () {
                Navigator.pop(context);
                _generateQuestionsForLevel(); // بازی مجدد همین مرحله
              },
              child: const Text(
                'تلاش مجدد ⚔️',
                style: TextStyle(fontFamily: 'Piramooz', color: Colors.white),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'نقشه مراحل',
              style: TextStyle(fontFamily: 'Piramooz', color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBarMessage(bool isCorrect, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Piramooz',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isCorrect
            ? Colors.green.shade800
            : Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  List<Color> _getButtonColors(TatiWord option) {
    if (!isAnswered) return [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)];
    if (option.id == currentQuestion!.id)
      return [Colors.green.shade700, Colors.green.shade900];
    if (option == selectedAnswer)
      return [Colors.red.shade700, Colors.red.shade900];
    return [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.epicGold),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141414), Color(0xFF2A2A2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // هدر بازی
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.epicGold,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'فصل ${widget.chapter} - مرحله ${widget.level}',
                          style: const TextStyle(
                            fontFamily: 'Piramooz',
                            color: AppColors.epicGold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // 👈 نمایش شماره سوال به جای جان‌ها
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.epicGold),
                      ),
                      child: Text(
                        'سوال ${currentQuestionIndex + 1} از 5',
                        style: const TextStyle(
                          fontFamily: 'Piramooz',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // نمایش سکه‌ها و کامبو
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: AppColors.epicGold,
                          size: 28,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$totalCoins',
                          style: const TextStyle(
                            fontFamily: 'Piramooz',
                            fontSize: 24,
                            color: AppColors.epicGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (comboStreak >= 3)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade900.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.yellowAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.yellowAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'x$comboStreak',
                              style: const TextStyle(
                                fontFamily: 'Piramooz',
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),

                // نوار زمان
                AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    double value = 1.0 - _timerController.value;
                    Color progressColor = Colors.green;
                    if (value < 0.5 && value > 0.2)
                      progressColor = Colors.orange;
                    if (value <= 0.2) progressColor = Colors.red;
                    if (isFreezeUsed) progressColor = Colors.lightBlueAccent;

                    return Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.epicGold.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.black45,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(flex: 1),

                // کارت سوال
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4EED7), Color(0xFFE3D5B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.epicGold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.epicGold.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'معادل تاتی این کلمه چیست؟',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF5A4D40),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          currentQuestion!.faWord,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Piramooz',
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: AppColors.bloodRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),

                // گزینه‌ها
                ...currentOptions.map((option) {
                  List<Color> buttonColors = _getButtonColors(option);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => _checkAnswer(option),
                      borderRadius: BorderRadius.circular(15),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: buttonColors,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                isAnswered && option.id == currentQuestion!.id
                                ? Colors.greenAccent
                                : AppColors.epicGold.withOpacity(0.7),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              option.tatiWord,
                              style: const TextStyle(
                                fontSize: 24,
                                color: AppColors.paperWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const Spacer(flex: 1),

                // دکمه‌های جادویی
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: is5050Used
                              ? Colors.grey.shade800
                              : const Color(0xFF1E5631),
                          side: BorderSide(
                            color: is5050Used
                                ? Colors.grey
                                : AppColors.epicGold,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _use5050,
                        icon: Icon(
                          Icons.content_cut,
                          color: is5050Used ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'حذف ۲ غلط (۲۰ سکه)',
                            style: TextStyle(
                              fontFamily: 'Piramooz',
                              fontSize: 14,
                              color: is5050Used ? Colors.grey : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFreezeUsed
                              ? Colors.grey.shade800
                              : Colors.blue.shade900,
                          side: BorderSide(
                            color: isFreezeUsed
                                ? Colors.grey
                                : Colors.lightBlueAccent,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _useFreezeTime,
                        icon: Icon(
                          Icons.ac_unit,
                          color: isFreezeUsed
                              ? Colors.grey
                              : Colors.lightBlueAccent,
                          size: 20,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'یخ زمان (۱۵ سکه)',
                            style: TextStyle(
                              fontFamily: 'Piramooz',
                              fontSize: 14,
                              color: isFreezeUsed ? Colors.grey : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
