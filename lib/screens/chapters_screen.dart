import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'levels_screen.dart';

class ChaptersScreen extends StatefulWidget {
  final String gameMode;

  const ChaptersScreen({Key? key, required this.gameMode}) : super(key: key);

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen>
    with SingleTickerProviderStateMixin {
  final int totalChapters = 20;
  List<bool> chapterUnlocked = [];
  List<bool> chapterCompleted = [];
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
    List<bool> tempUnlocked = List.filled(totalChapters, false);
    List<bool> tempCompleted = List.filled(totalChapters, false);
    tempUnlocked[0] = true;

    String prefix = widget.gameMode == 'puzzle' ? 'puzzle_' : '';

    for (int c = 1; c <= totalChapters; c++) {
      int level10Stars = prefs.getInt('${prefix}stars_c${c}_l10') ?? 0;
      if (level10Stars > 0) {
        tempCompleted[c - 1] = true;
        if (c < totalChapters) tempUnlocked[c] = true;
      }
    }
    setState(() {
      chapterUnlocked = tempUnlocked;
      chapterCompleted = tempCompleted;
      isLoading = false;
    });
  }

  // ---------------------------------------------------------
  // 🧩 بخش جدید: طراحی کاشی‌های پازلی (فقط برای حالت پازل)
  // ---------------------------------------------------------
  Widget _buildPuzzleGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // ۳ ستون در هر ردیف
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: totalChapters,
      itemBuilder: (context, index) {
        int chapterIndex = index + 1;
        bool isUnlocked = chapterUnlocked[index];
        bool isCompleted = chapterCompleted[index];
        bool isActive = isUnlocked && !isCompleted;

        return GestureDetector(
          onTap: () {
            if (isUnlocked) {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelsScreen(
                    chapter: chapterIndex,
                    gameMode: widget.gameMode,
                  ),
                ),
              ).then((_) => _loadProgress());
            } else {
              _showLockMessage();
            }
          },
          child: ScaleTransition(
            scale: isActive
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                // 👈 اگر مرحله تمام شده باشد، کاشی شیشه‌ای (شفاف) می‌شود تا عکس پشت دیده شود
                color: isCompleted
                    ? Colors.transparent
                    : (isUnlocked
                          ? Colors.blueGrey.withOpacity(0.8)
                          : Colors.black87),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? Colors.greenAccent.withOpacity(0.5)
                      : (isUnlocked ? AppColors.epicGold : Colors.white10),
                  width: 2,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 40,
                      ) // تیک تایید روی عکس
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isUnlocked ? Icons.extension : Icons.lock,
                            color: isUnlocked
                                ? AppColors.epicGold
                                : Colors.white24,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'فصل $chapterIndex',
                            style: TextStyle(
                              fontFamily: 'Piramooz',
                              color: isUnlocked ? Colors.white : Colors.white24,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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
          'فرمانده، این منطقه هنوز در غبار است! 🔒',
          style: TextStyle(fontFamily: 'Piramooz'),
        ),
        backgroundColor: Colors.red.shade900,
      ),
    );
  }

  // ---------------------------------------------------------
  // ⚔️ بخش قبلی: طراحی نقشه مارپیچ (فقط برای حالت کوییز)
  // ---------------------------------------------------------
  Widget _buildSagaMap() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      itemCount: totalChapters,
      itemBuilder: (context, index) {
        int chapterIndex = index + 1;
        bool isUnlocked = chapterUnlocked[index];
        bool isCompleted = chapterCompleted[index];
        bool isActive = isUnlocked && !isCompleted;
        bool isLeftAligned = index % 2 == 0;

        return Column(
          children: [
            Align(
              alignment: isLeftAligned
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  if (isUnlocked) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LevelsScreen(
                          chapter: chapterIndex,
                          gameMode: widget.gameMode,
                        ),
                      ),
                    ).then((_) => _loadProgress());
                  } else {
                    _showLockMessage();
                  }
                },
                child: _buildSagaNode(
                  chapterIndex,
                  isUnlocked,
                  isCompleted,
                  isActive,
                ),
              ),
            ),
            if (index < totalChapters - 1)
              _buildTrail(isLeftAligned, chapterUnlocked[index + 1]),
          ],
        );
      },
    );
  }

  Widget _buildSagaNode(
    int index,
    bool isUnlocked,
    bool isCompleted,
    bool isActive,
  ) {
    Color cardColor = isCompleted
        ? const Color(0xFF1E3A8A)
        : (isUnlocked ? const Color(0xFF14532D) : const Color(0xFF333333));
    return ScaleTransition(
      scale: isActive ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.epicGold, width: 3),
            ),
            child: Icon(
              isCompleted
                  ? Icons.flag
                  : (isUnlocked ? Icons.shield : Icons.lock),
              color: Colors.white,
              size: 40,
            ),
          ),
          Positioned(
            bottom: -10,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.epicGold,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'فصل $index',
                style: const TextStyle(
                  fontFamily: 'Piramooz',
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrail(bool isLeftToRight, bool isUnlocked) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.all(4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.epicGold : Colors.white10,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 👈 تصویر پس‌زمینه (مخصوص حالت پازل)
          if (widget.gameMode == 'puzzle')
            Positioned.fill(
              child: Image.asset(
                'assets/images/map_puzzle.jpg', // 👈 حتما این عکس رو اضافه کن
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.indigo.shade900),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                              ? 'پـازل فـتـوحـات'
                              : 'نـقـشـه نـبـرد',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Piramooz',
                            color: AppColors.epicGold,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                // 👈 تصمیم‌گیری برای نمایش نوع نقشه
                Expanded(
                  child: widget.gameMode == 'puzzle'
                      ? _buildPuzzleGrid()
                      : _buildSagaMap(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
