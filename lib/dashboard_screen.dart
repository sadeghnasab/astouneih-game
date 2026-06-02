import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userPhone;

  // موقع ورود به این صفحه، شماره موبایل کاربر رو بهش پاس می‌دیم
  const DashboardScreen({Key? key, required this.userPhone}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  // 🎯 آدرس سرور اصلی شما در لیارا (لینک برنامه Node.js)
  final String serverUrl = "https://astoniea-server.liara.run";

  @override
  void initState() {
    super.initState();
    _fetchProfile(); // به محض باز شدن صفحه، اطلاعات رو از سرور می‌گیریم
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/user/profile/${widget.userPhone}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });

        // 🚀 دستگاه شنود: این خط اطلاعات دریافتی رو تو کامپیوترت چاپ می‌کنه
        print("🚀 اطلاعات دریافت شده از سرور: $userData");
      } else {
        _showError("پرونده سرباز یافت نشد!");
      }
    } catch (e) {
      _showError("قطعی ارتباط با مرکز فرماندهی!");
    }
  }

  void _showError(String message) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // راست‌چین کردن کل صفحه برای زبان فارسی
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2C), // رنگ پس‌زمینه نظامی/تاریک
        appBar: AppBar(
          title: const Text(
            'قرارگاه اَستُونیه',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2A2D3E),
          elevation: 0,
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
            : userData == null
            ? const Center(
                child: Text(
                  "خطا در دریافت اطلاعات",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final String username = userData?['username'] ?? 'سربازِ گمنام';
    final int score = userData?['score'] ?? 0;
    final int kulalieh = userData?['kulalieh'] ?? 0;
    final String role = userData?['role'] ?? 'user';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🪪 کارت شناسایی سرباز
          Card(
            color: const Color(0xFF2A2D3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.userPhone,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 💎 بخش اقتصاد و امتیازات
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "امتیاز نبرد",
                  value: score.toString(),
                  icon: Icons.military_tech,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                  title: "کولالیه",
                  value: kulalieh.toString(),
                  icon: Icons.diamond,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          const Spacer(),

          // ⚔️ دکمه ورود به میدان نبرد
          ElevatedButton.icon(
            onPressed: () {
              // TODO: هدایت به صفحه رادار و پیدا کردن حریف
            },
            icon: const Icon(Icons.radar, size: 28),
            label: const Text("جستجوی حریف", style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.shade700,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 👑 دکمه مخفی ادمین (فقط فرماندهان می‌بینند!)
          if (role == 'admin')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdminScreen(adminPhone: widget.userPhone),
                  ),
                );
              },
              icon: const Icon(Icons.security, size: 28, color: Colors.white),
              label: const Text(
                "اتاق فرماندهی (پنل ادمین)",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade700,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ویجت کمکی برای ساختن کارت‌های امتیاز و کولالیه
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: const Color(0xFF2A2D3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
