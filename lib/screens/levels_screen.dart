import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'game_screen.dart';
import 'puzzle_screen.dart';

class LevelsScreen extends StatefulWidget {
  final int chapter;
  final String gameMode; // 'quiz' یا 'puzzle'

  const LevelsScreen({Key? key, required this.chapter, required this.gameMode})
    : super(key: key);

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen>
    with SingleTickerProviderStateMixin {
  final int totalLevels = 10;
  List<int> levelStars = [];
  List<bool> levelUnlocked = [];
  bool isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadLevelsProgress();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLevelsProgress() async {
    final prefs = await SharedPreferences.getInstance();
    List<int> tempStars = List.filled(totalLevels, 0);
    List<bool> tempUnlocked = List.filled(totalLevels, false);
    tempUnlocked[0] = true;

    // 👈 پیشوند هوشمند برای خوندن ستاره‌ها
    String prefix = widget.gameMode == 'puzzle' ? 'puzzle_' : '';

    for (int l = 1; l <= totalLevels; l++) {
      int stars = prefs.getInt('${prefix}stars_c${widget.chapter}_l$l') ?? 0;
      tempStars[l - 1] = stars;
      if (stars > 0 && l < totalLevels) {
        tempUnlocked[l] = true;
      }
    }

    setState(() {
      levelStars = tempStars;
      levelUnlocked = tempUnlocked;
      isLoading = false;
    });
  }

  // ---------------------------------------------------------
  // 🧩 بخش جدید: طراحی کاشی‌های پازلِ مراحل (فقط برای حالت پازل)
  // ---------------------------------------------------------
  Widget _buildPuzzleLevelGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 20,
        childAspectRatio: 0.95, // ارتفاع کمتر برای شبیه شدن به تیکه پازل
      ),
      itemCount: totalLevels,
      itemBuilder: (context, index) {
        int levelIndex = index + 1;
        bool isUnlocked = levelUnlocked[index];
        int stars = levelStars[index];
        bool isCompleted = stars > 0;
        bool isActive = isUnlocked && !isCompleted;

        return GestureDetector(
          onTap: () {
            if (isUnlocked) {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PuzzleScreen(chapter: widget.chapter, level: levelIndex),
                ),
              ).then((_) => _loadLevelsProgress());
            } else {
              _showLockMessage();
            }
          },
          child: ScaleTransition(
            scale: isActive
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                // 👈 گرادینت جدید و حرفه‌ای برای مراحل پازل
                gradient: isUnlocked
                    ? LinearGradient(
                        colors: isCompleted
                            ? [
                                const Color(0xFF1E3A8A),
                                const Color(0xFF0F172A),
                              ] // آبی سلطنتی
                            : [
                                const Color(0xFF14532D),
                                const Color(0xFF064E3B),
                              ], // سبز جنگلی
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade900, Colors.grey.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                // 👈 مرزهای طلایی و درخشان
                border: Border.all(
                  color: isActive
                      ? AppColors.epicGold
                      : (isCompleted
                            ? Colors.blueAccent
                            : Colors.grey.shade700),
                  width: isActive ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUnlocked
                        ? (isActive
                              ? AppColors.epicGold.withOpacity(0.5)
                              : Colors.black45)
                        : Colors.black26,
                    blurRadius: isActive ? 20 : 10,
                    spreadRadius: isActive ? 2 : 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 👈 آیکون اختصاصی پازل
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : (isUnlocked ? Icons.extension : Icons.lock),
                    color: isUnlocked
                        ? (isActive ? AppColors.epicGold : Colors.white70)
                        : Colors.white24,
                    size: 30,
                  ),
                  Text(
                    '$levelIndex',
                    style: TextStyle(
                      fontFamily: 'Piramooz',
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.white : Colors.white38,
                      shadows: isUnlocked
                          ? [
                              const Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                  ),
                  // 👈 سیستم ۳ ستاره پازل (درخشان‌تر)
                  if (isUnlocked)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (starIndex) {
                        bool isEarned = starIndex < stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0),
                          child: Icon(
                            isEarned ? Icons.star : Icons.star_border,
                            color: isEarned
                                ? const Color(0xFFFFD700)
                                : Colors.white24, // طلایی درخشان
                            size: 24,
                            shadows: isEarned
                                ? [
                                    const Shadow(
                                      color: Colors.orange,
                                      blurRadius: 10,
                                    ),
                                  ]
                                : [],
                          ),
                        );
                      }),
                    )
                  else
                    const Text(
                      'قفل',
                      style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'Piramooz',
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLockMessage() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'این منطقه هنوز در غبار است! 🔒',
          style: TextStyle(fontFamily: 'Piramooz', fontSize: 16),
        ),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ---------------------------------------------------------
  // ⚔️ بخش قبلی: طراحی شبکه مراحل کوییز (فقط برای حالت کوییز)
  // ---------------------------------------------------------
  Widget _buildQuizLevelGrid() {
    // ... کل کدهای GRIDVIEW.BUILDER قبلی را در اینجا قرار دهید (بدون تغییر) ...
    // ... برای جلوگیری از تکرار، من دوباره آنها را اینجا نمی‌نویسم ...
    // ... فقط یادتان باشد که به جای _PuzzleScreenState باید LevelsScreen(chapter: widget.chapter, level: levelIndex) ...
    // ... استفاده کنید. ...
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 25,
        childAspectRatio: 0.85,
      ),
      itemCount: totalLevels,
      itemBuilder: (context, index) {
        int levelIndex = index + 1;
        bool isUnlocked = levelUnlocked[index];
        int stars = levelStars[index];
        bool isCompleted = stars > 0;
        bool isActive = isUnlocked && !isCompleted;
        List<Color> cardGradient;
        Color borderColor;
        IconData statusIcon;
        Color iconColor;
        if (isCompleted) {
          cardGradient = [const Color(0xFF1E3A8A), const Color(0xFF0F172A)];
          borderColor = Colors.blueAccent;
          statusIcon = Icons.flag;
          iconColor = Colors.blueAccent.shade100;
        } else if (isUnlocked) {
          cardGradient = [const Color(0xFF14532D), const Color(0xFF064E3B)];
          borderColor = Colors.greenAccent;
          statusIcon = Icons.shield;
          iconColor = Colors.greenAccent.shade100;
        } else {
          cardGradient = [const Color(0xFF333333), const Color(0xFF1A1A1A)];
          borderColor = Colors.grey.shade700;
          statusIcon = Icons.lock;
          iconColor = Colors.white38;
        }
        Widget levelCard = GestureDetector(
          onTap: () {
            if (isUnlocked) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GameScreen(chapter: widget.chapter, level: levelIndex),
                ),
              ).then((_) => _loadLevelsProgress());
            } else {
              _showLockMessage();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: cardGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: borderColor, width: isActive ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: isUnlocked
                      ? borderColor.withOpacity(0.4)
                      : Colors.black54,
                  blurRadius: isActive ? 20 : 10,
                  spreadRadius: isActive ? 2 : 1,
                  offset: const Offset(0, 5),
                ),
                const BoxShadow(
                  color: Colors.white10,
                  blurRadius: 10,
                  spreadRadius: -5,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(statusIcon, color: iconColor, size: 28),
                Text(
                  '$levelIndex',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : Colors.white38,
                    shadows: isUnlocked
                        ? [
                            const Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                ),
                if (isUnlocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (starIndex) {
                      bool isEarned = starIndex < stars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(
                          isEarned ? Icons.star : Icons.star_border,
                          color: isEarned ? Colors.amber : Colors.white24,
                          size: 26,
                          shadows: isEarned
                              ? [
                                  const Shadow(
                                    color: Colors.orange,
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                      );
                    }),
                  )
                else
                  const Text(
                    'قفل',
                    style: TextStyle(
                      color: Colors.white38,
                      fontFamily: 'Piramooz',
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
        );
        if (isActive)
          levelCard = ScaleTransition(scale: _pulseAnimation, child: levelCard);
        return levelCard;
      },
    );
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
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1E1E),
            ], // تم دارک و حماسی (مثل chapters)
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- هدر صفحه مراحل ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.epicGold,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.gameMode == 'puzzle'
                            ? 'پـازل فـصـل ${widget.chapter}'
                            : 'مـراحـل فـصـل ${widget.chapter}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Piramooz',
                          color: AppColors.epicGold,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // --- تصمیم‌گیری برای نمایش نوعِ جدولِ مراحل ---
              Expanded(
                child: widget.gameMode == 'puzzle'
                    ? _buildPuzzleLevelGrid()
                    : _buildQuizLevelGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
