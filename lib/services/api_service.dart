import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // آدرس سرور چابکان خودت رو اینجا بذار (بدون /docs)
  // حتماً با https شروع بشه
  static const String baseUrl = 'https://dansfehan-game-api.chbk.dev';

  // فرستادن امتیاز به سرور
  static Future<bool> updateScore(String name, String avatar, int score) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'avatar': avatar, 'score': score}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('خطا در ارسال امتیاز: $e');
      return false;
    }
  }

  // گرفتن لیست نفرات برتر از سرور
  static Future<List<dynamic>> getTopPlayers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/top_players'));
      if (response.statusCode == 200) {
        // تبدیل دیتای سرور (JSON) به لیست فلاتر
        // برای اینکه کلمات فارسی خراب نشن، از utf8 استفاده میکنیم
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print('خطا در دریافت لیدربرد: $e');
    }
    return [];
  }

  // فرستادن کلمه جدید به سرور
  static Future<bool> sendNewWord(
    String playerName,
    String language,
    String city,
    String word,
    String translation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_word'),
        // اینجا charset=UTF-8 رو اضافه کردیم که حروف فارسی تو سرور علامت سوال نشن
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'player_name': playerName,
          'language': language,
          'city': city,
          'word': word,
          'translation': translation,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('خطا در ارسال کلمه: $e');
      return false;
    }
  }

  // ==========================================
  // تابع ثبت‌نام بازیکن (مجهز به سیستم دیباگ پیشرفته) 🕵️‍♂️
  // ==========================================
  static Future<bool> registerPlayer(
    String name,
    String phone,
    String avatar,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/add_player'); // 👈 آدرس مخفی و جدید
      print('📡 در حال ارسال درخواست ثبت‌نام به: $url'); // پیام دیباگ

      final response = await http
          .post(
            url,
            // برای هماهنگی بیشتر با پایتون، به صورت JSON می‌فرستیم
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'name': name, 'phone': phone, 'avatar': avatar}),
          )
          .timeout(const Duration(seconds: 30));

      print('✅ جواب سرور رسید! کد وضعیت: ${response.statusCode}'); // پیام دیباگ
      print('📄 متن جواب سرور: ${response.body}'); // پیام دیباگ

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ سرور پیدا شد، اما جواب موفقیت‌آمیز نداد!');
        return false;
      }
    } catch (e) {
      print('❌ ارور در اتصال: $e');
      // دیگه ارور رو پرت نمی‌کنیم بیرون که برنامه کرش کنه، فقط میگیم ثبت‌نام نشد
      return false;
    }
  }
}
