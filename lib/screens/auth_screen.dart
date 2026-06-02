import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
// 🚀 آدرس‌دهی دقیق بر اساس پوشه‌بندی شما (خروج از پوشه screens و دسترسی به فایل در ریشه lib)
import '../dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isOtpSent = false;
  bool isLoading = false;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // ⚠️ لینک سرور لیارای شما
  final String serverUrl = 'https://astoniea-server.liara.run';

  // 🚀 ارسال درخواست پیامک به سرور
  Future<void> sendOtp() async {
    if (phoneController.text.length < 10) {
      _showError('شماره موبایل نامعتبر است!');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phoneController.text}),
      );

      if (response.statusCode == 200) {
        setState(() {
          isOtpSent = true;
          isLoading = false;
        });
        _showSuccess('کد تایید به گوشی شما پیامک شد 📲');
      } else {
        setState(() => isLoading = false);
        _showError('خطا در ارسال پیامک!');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('خطا در ارتباط با سرور!');
    }
  }

  // 🔑 بررسی کد و ورود به پایگاه
  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phoneController.text,
          'code': otpController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];

        // 💾 ذخیره اطلاعات سرباز در حافظه گوشی با منطق حرفه‌ای
        final prefs = await SharedPreferences.getInstance();

        // ذخیره شماره موبایل (پلاک اصلی ورود که در main.dart چک می‌شود)
        await prefs.setString('userPhone', phoneController.text);

        // ذخیره سایر مشخصات برای استفاده در آینده
        await prefs.setString('userId', user['id'].toString());
        await prefs.setString('playerName', user['username'] ?? 'سربازِ گمنام');
        await prefs.setString('role', user['role'] ?? 'user');

        setState(() => isLoading = false);

        if (user['isNewUser'] == true) {
          _showSuccess('🎉 به ارتش اَستُونیه خوش آمدید!');
        } else {
          _showSuccess('به پایگاه برگشتی فرمانده!');
        }

        // 🚀 انتقال مستقیم به DashboardScreen (فایلی که در ریشه lib قرار دارد)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DashboardScreen(userPhone: phoneController.text),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        final errorData = jsonDecode(response.body);
        _showError(errorData['error'] ?? 'کد اشتباه است!');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('خطا در ارتباط با سرور!');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security,
                  size: 100,
                  color: AppColors.epicGold,
                ),
                const SizedBox(height: 20),
                const Text(
                  'دروازه امنیتی اَستُونیه',
                  style: TextStyle(
                    fontFamily: 'Piramooz',
                    fontSize: 32,
                    color: AppColors.epicGold,
                  ),
                ),
                const SizedBox(height: 40),

                // 📱 فیلد شماره موبایل
                TextField(
                  controller: phoneController,
                  enabled: !isOtpSent,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'شماره موبایل (مثلاً 0912...)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: AppColors.epicGold),
                    ),
                    prefixIcon: const Icon(
                      Icons.phone_android,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 🔢 فیلد کد تایید
                if (isOtpSent) ...[
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: 'کد ۴ رقمی',
                      counterText: "",
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        letterSpacing: 0,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 🔘 دکمه عملیات
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOtpSent
                          ? Colors.green.shade700
                          : AppColors.bloodRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : (isOtpSent ? verifyOtp : sendOtp),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isOtpSent ? 'تایید و ورود 🚀' : 'ارسال کد تایید 📩',
                            style: const TextStyle(
                              fontFamily: 'Piramooz',
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                if (isOtpSent)
                  TextButton(
                    onPressed: () => setState(() {
                      isOtpSent = false;
                      otpController.clear();
                    }),
                    child: const Text(
                      'ویرایش شماره موبایل',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Piramooz',
                      ),
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
