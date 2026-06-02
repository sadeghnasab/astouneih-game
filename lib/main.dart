import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'screens/auth_screen.dart';
import 'screens/main_menu.dart'; // 👈 برگشت به پناهگاه اصلی خودت

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jffuteefkxouwunnmrcj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmZnV0ZWVma3hvdXd1bm5tcmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NzAwMjIsImV4cCI6MjA5MDA0NjAyMn0.BNP8UGGaqJ9jXQifl4aHeq3pj4NGld7rTpXyt3gsCDk',
  );

  final prefs = await SharedPreferences.getInstance();
  // پلاک شناسایی رو از حافظه می‌خونیم
  final String? userPhone = prefs.getString('userPhone');
  final bool isAuthenticated = (userPhone != null && userPhone.isNotEmpty);

  runApp(TatiGameApp(isAuthenticated: isAuthenticated));
}

class TatiGameApp extends StatelessWidget {
  final bool isAuthenticated;
  const TatiGameApp({Key? key, required this.isAuthenticated})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اَستُونیه',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.darkBackground,
        primaryColor: AppColors.bloodRed,
        fontFamily: 'Morvarid',
      ),
      // اگر قبلاً وارد شده بود، مستقیم بره منوی اصلی
      home: isAuthenticated ? const MainMenu() : const AuthScreen(),
    );
  }
}
