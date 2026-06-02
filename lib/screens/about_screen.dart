import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'package:shimmer/shimmer.dart'; // حتماً این پکیج رو در بالا چک کن
import '../core/history_data.dart'; // بستگی به مسیری داره که فایل رو ساختی

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool isSfxEnabled = true;
  final AudioPlayer _sfxPlayer = AudioPlayer();

  // ==========================================
  // 📚 دسته‌بندی‌های تاریخچه دانسفهان (بر اساس کتاب)
  // ==========================================

  void _playSound(String fileName) async {
    if (isSfxEnabled) {
      await _sfxPlayer.play(AssetSource('audio/$fileName'));
    }
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'درباره دانسفهان 🏰',
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
            _playSound('bubble.mp3');
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: AppColors.epicGold, height: 2.0),
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
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: HistoryData.aboutCategories.length,
          itemBuilder: (context, index) {
            final category = HistoryData.aboutCategories[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _playSound('bubble.mp3');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailScreen(
                        title: category["title"],
                        content: category["content"],
                        color: category["color"],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 15,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [category["color"], const Color(0xFF1E1E1E)],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.epicGold.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.epicGold,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          category["icon"],
                          color: AppColors.epicGold,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          category["title"],
                          style: const TextStyle(
                            fontFamily: 'Piramooz',
                            fontSize: 24,
                            color: AppColors.paperWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// صفحه نمایش متن داخل هر دسته‌بندی (شبیه طومار)
// ==========================================

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final Color color;

  const CategoryDetailScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: color,
        title: Shimmer.fromColors(
          // 👈 افکت درخشش روی تیتر آپ‌بار
          baseColor: AppColors.paperWhite,
          highlightColor: Colors.amberAccent,
          child: Text(
            title,
            style: const TextStyle(fontFamily: 'Piramooz', fontSize: 22),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.paperWhite),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141414), Color(0xFF2A2A2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EED7), // رنگ کاغذ قدیمی
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color, width: 4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // 🛡️ آیکون بالای صفحه با هاله نور
                Icon(Icons.auto_stories, color: color, size: 50),

                // 📜 جداکننده گرافیکی به جای خط ساده
                _buildFancyDivider(color),

                const SizedBox(height: 10),

                // 📝 متن اصلی با استایل بهبود یافته
                Text(
                  content,
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.9, // فاصله بین خطوط بیشتر برای خوانایی
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Morvarid',
                  ),
                ),

                const SizedBox(height: 30),

                // ⚔️ جداکننده انتهایی
                _buildFancyDivider(color),

                const SizedBox(height: 10),
                const Text(
                  '❦ برگرفته از کتاب تاریخ دانسفهان ❦',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 متد کمکی برای ساخت جداکننده شیک باستانی
  Widget _buildFancyDivider(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.star, color: color, size: 15),
          ),
          Expanded(child: Divider(color: color.withOpacity(0.3), thickness: 2)),
        ],
      ),
    );
  }
}
