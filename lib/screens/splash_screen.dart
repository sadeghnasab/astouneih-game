import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'main_menu.dart';
import 'registration_screen.dart'; // 👈 اضافه شد برای هدایت هوشمند

class AnimatedSplashScreen extends StatefulWidget {
  // این متغیر را اضافه کردیم تا وضعیت ثبت‌نام را از ورودی بگیریم
  final bool isRegistered;

  const AnimatedSplashScreen({Key? key, required this.isRegistered})
    : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // ⏱️ تنظیم تایمر برای انتقال هوشمند بعد از ۴ ثانیه
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                // اگر ثبت‌نام کرده بود برو منو، در غیر این صورت برو ثبت‌نام
                widget.isRegistered
                ? const MainMenu()
                : const RegistrationScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // پس‌زمینه سیاه سینمایی
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 لوگوی اصلی با هاله نور طلایی (Glow) در پشت آن
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/icon.png', height: 160),
                ),
                const SizedBox(height: 30),

                // 🌟 افکت درخشش روی اسم «اَستُونیه»
                Shimmer.fromColors(
                  baseColor: const Color(0xFFFFD700), // طلایی
                  highlightColor: Colors.white, // درخشش سفید
                  period: const Duration(milliseconds: 2500),
                  child: const Text(
                    'اَستُونیه',
                    style: TextStyle(
                      fontFamily: 'Piramooz',
                      fontSize: 55,
                      shadows: [
                        Shadow(
                          color: Colors.white24,
                          blurRadius: 20,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'گروه دانش‌بنیان فدک',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    fontSize: 24,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),

                const Text(
                  'دانسفهان',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    fontSize: 18,
                    color: Colors.blueAccent,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
