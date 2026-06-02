import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/constants.dart';
import '../services/api_service.dart'; // اضافه شدن سرویس سرور
import 'splash_screen.dart'; // رفتن به صفحه سینمایی بعد از ثبت‌نام
import 'dart:io'; // 👈 این خط برای چک کردن اینترنت اضافه شد

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // فیلد جدید شماره تماس
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isSubmitting = false; // برای نشون دادن لودینگ موقع ارسال به سرور
  int selectedAvatarIndex = 0;
  bool isSfxEnabled = true;

  // لیست آواتارهای باستانی (نمادهای مبارزان)
  final List<String> avatars = [
    '🦅',
    '🦁',
    '🐺',
    '🐻',
    '🦉',
    '🐉',
    '⚔️',
    '🛡️',
  ];

  @override
  void initState() {
    super.initState();
    _loadSoundSettings();
  }

  Future<void> _loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSfxEnabled = prefs.getBool('isSfxEnabled') ?? true;
    });
  }

  void _playSound(String fileName) async {
    if (isSfxEnabled) {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    }
  }

  // ==========================================
  // تابع ثبت‌نام و اتصال به مقر فرماندهی (سرور)
  // ==========================================
  Future<void> _registerUserAndStart() async {
    String playerName = _nameController.text.trim();
    String playerPhone = _phoneController.text.trim();

    if (playerName.isEmpty || playerName.length < 3) {
      _showSnackBar('نام جنگجو باید حداقل ۳ حرف باشد! ⚠️');
      HapticFeedback.heavyImpact();
      _playSound('shield.mp3');
      return;
    }

    // 📡 --- سیستم هوشمند بررسی اینترنت --- 📡
    try {
      // تلاش برای پینگ گرفتن (اگه اینترنت قطع باشه، سریع ارور میده)
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('بدون اینترنت');
      }
    } on SocketException catch (_) {
      // ❌ اگر اینترنت قطع بود، این پیام گرافیکی و شیک ظاهر میشه
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.wifi_off, color: Colors.white, size: 28),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  'ارتباط با مقر فرماندهی قطع است!\nلطفاً اینترنت خود را روشن کنید 📡',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ), // گوشه‌های گرد
          margin: const EdgeInsets.all(20), // فاصله از لبه‌های صفحه
          duration: const Duration(seconds: 4), // ۴ ثانیه روی صفحه میمونه
        ),
      );
      HapticFeedback.heavyImpact(); // ویبره هشدار
      return; // ⛔ توقف عملیات تا وقتی کاربر اینترنت رو وصل کنه
    }
    // ------------------------------------

    setState(() => isSubmitting = true); // روشن کردن چرخ‌دنده لودینگ

    // ارسال اطلاعات به سرور
    bool success = await ApiService.registerPlayer(
      playerName,
      playerPhone,
      avatars[selectedAvatarIndex],
    );

    setState(() => isSubmitting = false); // خاموش کردن لودینگ

    if (success) {
      // ذخیره اطلاعات در حافظه گوشی
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isRegistered', true); // تیک ثبت‌نام خورد!
      await prefs.setString('playerName', playerName);
      await prefs.setString('playerAvatar', avatars[selectedAvatarIndex]);
      if (playerPhone.isNotEmpty)
        await prefs.setString('playerPhone', playerPhone);

      // دادن سکه هدیه برای شروع بازی
      if (!prefs.containsKey('totalCoins')) {
        await prefs.setInt('totalCoins', 100);
      }

      HapticFeedback.lightImpact();
      _playSound('sword.mp3');

      if (!mounted) return;

      // انتقال با انیمیشن محو شدن به صفحه سینمایی
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AnimatedSplashScreen(isRegistered: true),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      // اگر اینترنت وصل بود اما سرور جواب نداد
      if (!mounted) return;
      _showSnackBar('سرور در حال استراحت است! دقایقی دیگر تلاش کن. 🏰');
      HapticFeedback.heavyImpact();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Piramooz', fontSize: 18),
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: true,
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.castle, color: AppColors.epicGold, size: 80),
                const SizedBox(height: 15),
                const Text(
                  'دروازه ورود',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    color: AppColors.epicGold,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'به سرزمین کلمات و خرد خوش آمدید',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // انتخاب آواتار
                const Text(
                  'نشان خود را انتخاب کن:',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    color: AppColors.paperWhite,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: avatars.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedAvatarIndex == index;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _playSound('bubble.mp3');
                          setState(() => selectedAvatarIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 70,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.bloodRed
                                : const Color(0xFF3A3A3A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.epicGold
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.bloodRed.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              avatars[index],
                              style: TextStyle(fontSize: isSelected ? 35 : 30),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // فیلد دریافت نام
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Piramooz',
                    color: AppColors.epicGold,
                    fontSize: 24,
                  ),
                  decoration: InputDecoration(
                    hintText: 'نام جنگجویانه شما...',
                    hintStyle: TextStyle(
                      fontFamily: 'Piramooz',
                      color: Colors.grey.shade600,
                      fontSize: 20,
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppColors.epicGold,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.person,
                      color: AppColors.epicGold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // فیلد جدید: دریافت شماره تماس
                TextField(
                  controller: _phoneController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'شماره تماس (برای دریافت جوایز)',
                    hintStyle: TextStyle(
                      fontFamily: 'Piramooz',
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppColors.epicGold,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_android,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // دکمه آغاز نبرد و ارسال به سرور
                isSubmitting
                    ? const CircularProgressIndicator(
                        color: AppColors.epicGold,
                      ) // نمایش لودینگ در حین ارسال
                    : InkWell(
                        onTap: _registerUserAndStart,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.bloodRed, Color(0xFF5A0000)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.epicGold,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'عبور از دروازه ⚔️',
                              style: TextStyle(
                                fontFamily: 'Piramooz',
                                fontSize: 26,
                                color: AppColors.epicGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
