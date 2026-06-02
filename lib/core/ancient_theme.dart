import 'dart:math';
import 'package:flutter/material.dart';

// ==========================================
// 🏛️ قاب جادویی و باستانی برای کل صفحات برنامه
// ==========================================
class AncientIslamicTheme extends StatelessWidget {
  final Widget child;

  const AncientIslamicTheme({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ۱. پس‌زمینه تیره با پترن اسلیمی (می‌تونی بعداً عکس اسلیمی بهش بدی)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF141414), // رنگ مشکی/قهوه‌ای خیلی تیره
            // اگر عکس پترن اسلیمی داشتی این کامنت رو بردار:
            // image: DecorationImage(
            //   image: AssetImage('assets/images/islamic_pattern.png'),
            //   repeat: ImageRepeat.repeat,
            //   opacity: 0.05, // خیلی محو و شیک
            // ),
          ),
        ),

        // ۲. 🌟 ذرات نورانی معلق در فضا (موشن گرافیک)
        const GlowingParticles(),

        // ۳. محتوای اصلی صفحه (که تو بهش میدی)
        child,

        // ۴. 🖼️ حاشیه و قاب نفیس اسلیمی (روی همه چیز قرار میگیره)
        IgnorePointer(
          // برای اینکه مزاحم کلیک کردن دکمه‌ها نشه
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(
                  0xFFD4AF37,
                ).withOpacity(0.3), // رنگ طلایی حاشیه
                width: 3,
              ),
              borderRadius: BorderRadius.circular(5),
              // اگر قاب تذهیب PNG داشتی این کامنت رو بردار:
              // image: DecorationImage(
              //   image: AssetImage('assets/images/tazhib_border.png'),
              //   fit: BoxFit.fill,
              // ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// ✨ سیستم تولید ذرات نورانی و معلق (غبار طلایی)
// ==========================================
class GlowingParticles extends StatefulWidget {
  const GlowingParticles({Key? key}) : super(key: key);

  @override
  State<GlowingParticles> createState() => _GlowingParticlesState();
}

class _GlowingParticlesState extends State<GlowingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final int _particleCount = 30; // تعداد ذرات نورانی
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(_particleCount, (_) => _Particle(_random));
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            setState(() {
              for (var p in _particles) {
                p.move();
              }
            });
          })
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles),
      size: Size.infinite,
    );
  }
}

class _Particle {
  double x, y, speed, size;
  final Random random;

  _Particle(this.random)
    : x = random.nextDouble(),
      y = random.nextDouble(),
      speed = 0.0005 + random.nextDouble() * 0.001,
      size = 1.0 + random.nextDouble() * 2.5;

  void move() {
    y -= speed; // حرکت آرام به سمت بالا
    x += (random.nextDouble() - 0.5) * 0.002; // لرزش ریز به چپ و راست
    if (y < 0) {
      y = 1.0;
      x = random.nextDouble();
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
          .withOpacity(0.6) // رنگ طلایی نور
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // هاله درخشان

    for (var p in particles) {
      final offset = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(offset, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
