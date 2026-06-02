import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import '../core/constants.dart';
import '../models/word_model.dart';
import '../data/game_logic.dart';
import 'package:flutter/services.dart';

class PuzzleLetter {
  final int id;
  final String char;
  bool isUsed;
  bool isFromHint; // 👈 فیلد جدید برای تشخیص حروف راهنما

  PuzzleLetter(this.id, this.char, this.isUsed, {this.isFromHint = false});
}

class PuzzleScreen extends StatefulWidget {
  final int chapter;
  final int level;

  const PuzzleScreen({Key? key, this.chapter = 1, this.level = 1})
    : super(key: key);

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with TickerProviderStateMixin {
  List<TatiWord> allWords = [];
  List<TatiWord> levelQuestions = [];
  bool isLoading = true;

  int currentQuestionIndex = 0;
  int correctAnswersCount = 0;

  late TatiWord currentQuestion;

  int totalCoins = 0;
  int lives = 3;
  bool isSfxEnabled = true;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  // --- انیمیشن جدید راهنما ---
  late AnimationController _hintAnimationController;
  late Animation<Offset> _hintSlideAnimation;
  late Animation<double> _hintFadeAnimation;
  PuzzleLetter? _animatedLetter; // حرفی که در حال انیمیشن است

  List<PuzzleLetter> puzzleLetters = [];
  List<PuzzleLetter> selectedLetters = [];
  int targetLength = 0;
  String correctTatiWordNoSpaces = "";

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _loadData();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // 👈 تنظیمات انیمیشن سقوط راهنما
    _hintAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _hintSlideAnimation =
        Tween<Offset>(
          begin: const Offset(0, -3), // از ۳ برابر ارتفاع بالاتر
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _hintAnimationController,
            curve: Curves.easeOutBack,
          ),
        );

    _hintFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintAnimationController, curve: Curves.easeIn),
    );
  }

  Future<void> _loadData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/tati_words.json',
      );
      final List<dynamic> data = json.decode(response);
      allWords = data.map((json) => TatiWord.fromJson(json)).toList();

      allWords.shuffle(Random());
      levelQuestions = allWords.take(5).toList();

      setState(() {
        currentQuestionIndex = 0;
        correctAnswersCount = 0;
        isLoading = false;
      });

      _setupStage();
    } catch (e) {
      debugPrint("خطا در بارگذاری کلمات: $e");
    }
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

  void _setupStage() {
    if (levelQuestions.isEmpty) return;

    currentQuestion = levelQuestions[currentQuestionIndex];
    correctTatiWordNoSpaces = currentQuestion.tatiWord.replaceAll(' ', '');
    targetLength = correctTatiWordNoSpaces.length;

    List<String> rawLetters = GameLogic.generatePuzzleLetters(
      currentQuestion.tatiWord,
    );

    setState(() {
      puzzleLetters = List.generate(
        rawLetters.length,
        (index) => PuzzleLetter(index, rawLetters[index], false),
      );
      selectedLetters.clear();
      lives = 3;
      _animatedLetter = null; // ریست کردن انیمیشن
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _hintAnimationController.dispose(); // 👈 دیسپوز انیمیشن
    super.dispose();
  }

  void _playSound(String fileName) async {
    if (isSfxEnabled) {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    }
  }

  void _shuffleLetters() {
    HapticFeedback.selectionClick();
    _playSound('bubble.mp3');
    setState(() => puzzleLetters.shuffle());
  }

  // 👈 تابع راهنما با انیمیشن جادویی و رفع باگ
  void _useHint() async {
    HapticFeedback.selectionClick();
    if (_hintAnimationController.isAnimating) return; // جلوگیری از کلیک اسپم

    if (totalCoins < 30) {
      _showSnackBarMessage(false, 'سکه کافی نیست! (۳۰ سکه نیاز است) 💰');
      return;
    }

    // ۱. پیدا کردن اولین خونه‌ای که یا خالیه یا غلط پر شده
    int correctIndex = -1;
    for (int i = 0; i < targetLength; i++) {
      if (i >= selectedLetters.length ||
          selectedLetters[i].char != correctTatiWordNoSpaces[i]) {
        correctIndex = i;
        break;
      }
    }

    if (correctIndex != -1) {
      // ۲. اگر از اون خونه به بعد هر چی چیده شده غلطه، همه رو پاک کن
      while (selectedLetters.length > correctIndex) {
        PuzzleLetter removed = selectedLetters.removeLast();
        removed.isUsed = false;
        removed.isFromHint = false; // اگر حرف راهنما بود، اثرش رو پاک کن
      }

      // ۳. حالا حرفِ درستِ این خونه رو پیدا کن
      String neededChar = correctTatiWordNoSpaces[correctIndex];
      int letterIndex = puzzleLetters.indexWhere(
        (p) => p.char == neededChar && !p.isUsed,
      );

      if (letterIndex != -1) {
        _playSound('sword.mp3');
        _updateWallet(-30);

        setState(() {
          PuzzleLetter targetLetter = puzzleLetters[letterIndex];
          targetLetter.isUsed = true;
          targetLetter.isFromHint = true; // 👈 مارک کردن به عنوان حرف راهنما
          _animatedLetter = targetLetter; // تعیین حرف برای انیمیشن
        });

        // ۴. اجرای انیمیشن سقوط
        await _hintAnimationController.forward(from: 0.0);

        setState(() {
          selectedLetters.add(
            _animatedLetter!,
          ); // اضافه کردن واقعی به لیست بعد از انیمیشن
          _animatedLetter = null; // پاک کردن از حالت انیمیشن
        });

        if (selectedLetters.length == targetLength) _checkAnswer();
      }
    }
  }

  void _removeSpecificLetter(int index) {
    if (index >= selectedLetters.length) return;
    PuzzleLetter letterToRemove = selectedLetters[index];

    // 👈 قانون جدید: حروف راهنما (طلایی) قابل حذف نیستند!
    if (letterToRemove.isFromHint) {
      HapticFeedback.heavyImpact();
      _playSound('shield.mp3');
      _showSnackBarMessage(false, 'حروف جادویی راهنما قابل حذف نیستند! 🔮');
      return;
    }

    HapticFeedback.selectionClick();
    _playSound('bubble.mp3');

    setState(() {
      letterToRemove.isUsed = false;
      selectedLetters.removeAt(index);
    });
  }

  void _undoLastLetter() {
    if (selectedLetters.isEmpty) return;
    PuzzleLetter lastLetter = selectedLetters.last;

    // 👈 قانون جدید: حروف راهنما (طلایی) قابل حذف نیستند!
    if (lastLetter.isFromHint) {
      HapticFeedback.heavyImpact();
      _playSound('shield.mp3');
      _showSnackBarMessage(false, 'حروف جادویی راهنما قابل حذف نیستند! 🔮');
      return;
    }

    HapticFeedback.selectionClick();
    _playSound('bubble.mp3');

    setState(() {
      lastLetter.isUsed = false;
      selectedLetters.removeLast();
    });
  }

  void _onLetterTapped(PuzzleLetter letter) {
    if (letter.isUsed ||
        selectedLetters.length >= targetLength ||
        _hintAnimationController.isAnimating)
      return;
    HapticFeedback.selectionClick();
    _playSound('bubble.mp3');

    setState(() {
      letter.isUsed = true;
      letter.isFromHint = false; // حروف عادی راهنما نیستند
      selectedLetters.add(letter);
    });

    if (selectedLetters.length == targetLength) _checkAnswer();
  }

  void _checkAnswer() async {
    String userAnswer = selectedLetters.map((l) => l.char).join('');
    bool isCorrect = userAnswer == correctTatiWordNoSpaces;

    if (isCorrect) {
      HapticFeedback.lightImpact();
      correctAnswersCount++;
      _playSound('sword.mp3');
      _confettiController.play();
      _showWordResultDialog(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => lives -= 1);
      _playSound('shield.mp3');

      if (lives <= 0) {
        _showWordResultDialog(false);
      } else {
        _showSnackBarMessage(
          false,
          'حروف اشتباه است! (فرصت باقی‌مانده: $lives) 🛡️',
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          setState(() {
            // فقط حروف غیر راهنما رو پاک کن
            selectedLetters.removeWhere((letter) {
              if (!letter.isFromHint) {
                letter.isUsed = false;
                return true;
              }
              return false;
            });
          });
        });
      }
    }
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
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _showWordResultDialog(bool wasCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: wasCorrect ? Colors.greenAccent : AppColors.bloodRed,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          wasCorrect ? 'آفرین! دقیق بود 🎉' : 'کلمه سوخت! 💔',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: wasCorrect ? Colors.greenAccent : AppColors.bloodRed,
            fontFamily: 'Piramooz',
            fontSize: 28,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تلفظ و معنی کلمه:',
              style: TextStyle(
                color: AppColors.paperWhite,
                fontSize: 16,
                fontFamily: 'Piramooz',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              currentQuestion.tatiWord,
              style: const TextStyle(
                color: AppColors.epicGold,
                fontSize: 35,
                fontWeight: FontWeight.bold,
                fontFamily: 'Piramooz',
              ),
            ),
            Text(
              '[ ${currentQuestion.pronunciation} ]',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 20,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 15),
            Text(
              'معنی: ${currentQuestion.faWord}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Piramooz',
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bloodRed,
              side: const BorderSide(color: AppColors.epicGold, width: 1.5),
            ),
            onPressed: () {
              Navigator.pop(context);
              _goToNextQuestionOrFinish();
            },
            child: const Text(
              'ادامه',
              style: TextStyle(
                fontFamily: 'Piramooz',
                fontSize: 20,
                color: AppColors.epicGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextQuestionOrFinish() {
    if (currentQuestionIndex < 4) {
      setState(() => currentQuestionIndex++);
      _setupStage();
    } else {
      _showLevelCompleteDialog();
    }
  }

  Future<void> _showLevelCompleteDialog() async {
    int stars = 0;
    if (correctAnswersCount == 3) stars = 1;
    if (correctAnswersCount == 4) stars = 2;
    if (correctAnswersCount == 5) stars = 3;

    bool isVictory = stars > 0;

    if (isVictory) {
      _playSound('sword.mp3');
      int bonusCoins = stars * 15;
      _updateWallet(bonusCoins);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'puzzle_stars_c${widget.chapter}_l${widget.level}',
        stars,
      );
      await prefs.setBool(
        'puzzle_unlocked_c${widget.chapter}_l${widget.level + 1}',
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
              'کلماتِ ساخته شده: $correctAnswersCount از ۵',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Piramooz',
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (isVictory)
              Text(
                'پاداش فتح: +${stars * 15} سکه',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontFamily: 'Piramooz',
                ),
              )
            else
              const Text(
                'باید حداقل ۳ کلمه را درست بسازید!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isVictory
                  ? Colors.green.shade800
                  : AppColors.bloodRed,
              side: const BorderSide(color: AppColors.epicGold, width: 1.5),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'نقشه مراحل',
              style: TextStyle(fontFamily: 'Piramooz', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 👈 ویجت اختصاصی برای نمایش هر حرف در خونه‌های خالی
  Widget _buildLetterBox(PuzzleLetter letter, {bool isAnimated = false}) {
    // 👈 قانون رنگ جدید: حروف راهنما طلایی، حروف عادی سفید
    Color textColor = letter.isFromHint
        ? AppColors.epicGold
        : AppColors.bloodRed;
    Color boxColor = letter.isFromHint ? Colors.black87 : AppColors.paperWhite;
    Color borderColor = letter.isFromHint
        ? AppColors.epicGold
        : AppColors.epicGold;

    Widget content = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: boxColor,
        border: Border.all(
          color: borderColor,
          width: letter.isFromHint ? 3 : 2,
        ), // مرز ضخیم‌تر برای راهنما
        borderRadius: BorderRadius.circular(10),
        boxShadow: letter.isFromHint
            ? [const BoxShadow(color: AppColors.epicGold, blurRadius: 10)]
            : [], // درخشش برای راهنما
      ),
      child: Center(
        child: Text(
          letter.char,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );

    // اگر حالت انیمیشن است، افکت سقوط و محو شدن را اضافه کن
    if (isAnimated) {
      return SlideTransition(
        position: _hintSlideAnimation,
        child: FadeTransition(opacity: _hintFadeAnimation, child: content),
      );
    }

    return content;
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
      body: Stack(
        children: [
          Container(
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
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.epicGold,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _playSound('bubble.mp3');
                            Navigator.pop(context);
                          },
                        ),
                        Column(
                          children: [
                            Text(
                              'فصل ${widget.chapter} - مرحله ${widget.level}',
                              style: const TextStyle(
                                fontFamily: 'Piramooz',
                                color: AppColors.epicGold,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.epicGold,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'کلمه ${currentQuestionIndex + 1} از 5',
                                style: const TextStyle(
                                  fontFamily: 'Piramooz',
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: List.generate(
                            3,
                            (index) => Icon(
                              index < lives
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: AppColors.bloodRed,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            fontSize: 26,
                            color: AppColors.epicGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      currentQuestion.faWord,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Piramooz',
                        fontSize: 45,
                        fontWeight: FontWeight.w900,
                        color: AppColors.paperWhite,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- بخش چیدمان حروف (با پشتیبانی از انیمیشن) ---
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      textDirection: TextDirection.rtl,
                      children: List.generate(targetLength, (index) {
                        bool hasLetter = index < selectedLetters.length;
                        bool isAnimatingNode =
                            (_animatedLetter != null &&
                            index == selectedLetters.length);

                        return GestureDetector(
                          onTap: () {
                            if (hasLetter) _removeSpecificLetter(index);
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // خونه‌ی خالی (مرز)
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(
                                    color: AppColors.epicGold.withOpacity(0.5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // اگر حرف چیده شده بود، نمایش بده
                              if (hasLetter)
                                _buildLetterBox(selectedLetters[index]),

                              // اگر در حال اجرای انیمیشن راهنما برای این خونه هستیم
                              if (isAnimatingNode)
                                _buildLetterBox(
                                  _animatedLetter!,
                                  isAnimated: true,
                                ),
                            ],
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.backspace,
                        color: Colors.white70,
                        size: 30,
                      ),
                      onPressed: _undoLastLetter,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.bloodRed,
                            side: const BorderSide(
                              color: AppColors.epicGold,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _useHint,
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'راهنما (۳۰ سکه)',
                            style: TextStyle(
                              fontFamily: 'Piramooz',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E5631),
                            side: const BorderSide(
                              color: AppColors.epicGold,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _shuffleLetters,
                          icon: const Icon(Icons.sync, color: Colors.white),
                          label: const Text(
                            'گردباد (رایگان)',
                            style: TextStyle(
                              fontFamily: 'Piramooz',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.epicGold.withOpacity(0.5),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 15,
                        runSpacing: 15,
                        textDirection: TextDirection.rtl,
                        children: puzzleLetters.map((puzzleLetter) {
                          return InkWell(
                            onTap: () => _onLetterTapped(puzzleLetter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: puzzleLetter.isUsed
                                      ? [
                                          Colors.grey.shade800,
                                          Colors.grey.shade900,
                                        ]
                                      : [
                                          const Color(0xFF3A3A3A),
                                          const Color(0xFF1E1E1E),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: puzzleLetter.isUsed
                                      ? Colors.grey
                                      : AppColors.epicGold,
                                  width: 2,
                                ),
                                boxShadow: puzzleLetter.isUsed
                                    ? []
                                    : [
                                        const BoxShadow(
                                          color: Colors.black54,
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: Text(
                                  puzzleLetter.char,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: puzzleLetter.isUsed
                                        ? Colors.grey.shade600
                                        : AppColors.epicGold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
