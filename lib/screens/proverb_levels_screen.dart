import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'proverb_screen.dart';

class ProverbLevelsScreen extends StatefulWidget {
  const ProverbLevelsScreen({Key? key}) : super(key: key);

  @override
  State<ProverbLevelsScreen> createState() => _ProverbLevelsScreenState();
}

class _ProverbLevelsScreenState extends State<ProverbLevelsScreen>
    with SingleTickerProviderStateMixin {
  final int totalLevels = 46; // 👈 تعداد دقیق مراحل خردمندان
  List<int> levelStars = [];
  List<bool> levelUnlocked = [];
  bool isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadProgress();

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

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    List<int> tempStars = List.filled(totalLevels, 0);
    List<bool> tempUnlocked = List.filled(totalLevels, false);

    // مرحله اول همیشه بازه
    tempUnlocked[0] = true;

    // خوندنِ شماره آخرین مرحله‌ای که کاربر باز کرده
    int unlockedLevel = prefs.getInt('unlockedProverbLevel') ?? 1;

    for (int i = 0; i < totalLevels; i++) {
      int stage = i + 1;
      tempStars[i] = prefs.getInt('proverb_stars_l$stage') ?? 0;
      if (stage <= unlockedLevel) {
        tempUnlocked[i] = true;
      }
    }

    setState(() {
      levelStars = tempStars;
      levelUnlocked = tempUnlocked;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2A0845),
              Color(0xFF1A1A1A),
            ], // تم بنفش/تاریک مخصوص خردمندان
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- هدر صفحه ---
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
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'تـالار خـردمـنـدان',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Piramooz',
                          color: Colors.amber,
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

              // --- گرید ۴۶ مرحله‌ای ---
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // ۳ ستون در هر ردیف
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: totalLevels,
                  itemBuilder: (context, index) {
                    int levelIndex = index + 1;
                    bool isUnlocked = levelUnlocked[index];
                    int stars = levelStars[index];
                    bool isCompleted = stars > 0;
                    bool isActive = isUnlocked && !isCompleted;

                    Widget levelCard = GestureDetector(
                      onTap: () {
                        if (isUnlocked) {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProverbScreen(stageNumber: levelIndex),
                            ),
                          ).then((_) => _loadProgress());
                        } else {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'طومارِ این مرحله مهر و موم است! 🔒',
                                style: TextStyle(
                                  fontFamily: 'Piramooz',
                                  fontSize: 16,
                                ),
                              ),
                              backgroundColor: Colors.red.shade900,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCompleted
                                ? [
                                    Colors.purple.shade800,
                                    Colors.purple.shade900,
                                  ]
                                : (isUnlocked
                                      ? [
                                          const Color(0xFF8B5A2B),
                                          const Color(0xFF5A0000),
                                        ]
                                      : [
                                          Colors.grey.shade800,
                                          Colors.grey.shade900,
                                        ]),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isActive
                                ? Colors.amber
                                : (isCompleted
                                      ? Colors.purpleAccent
                                      : Colors.grey.shade700),
                            width: isActive ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUnlocked
                                  ? Colors.black54
                                  : Colors.transparent,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(
                              isCompleted
                                  ? Icons.history_edu
                                  : (isUnlocked ? Icons.menu_book : Icons.lock),
                              color: isUnlocked ? Colors.amber : Colors.white38,
                              size: 24,
                            ),
                            Text(
                              '$levelIndex',
                              style: TextStyle(
                                fontFamily: 'Piramooz',
                                fontSize: 35,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.white38,
                              ),
                            ),
                            if (isUnlocked)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (starIndex) {
                                  bool isEarned = starIndex < stars;
                                  return Icon(
                                    isEarned ? Icons.star : Icons.star_border,
                                    color: isEarned
                                        ? Colors.amber
                                        : Colors.white24,
                                    size: 16,
                                  );
                                }),
                              )
                            else
                              const Text(
                                'قفل',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontFamily: 'Piramooz',
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );

                    if (isActive)
                      levelCard = ScaleTransition(
                        scale: _pulseAnimation,
                        child: levelCard,
                      );
                    return levelCard;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
