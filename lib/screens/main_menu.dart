import 'dart:math';
import 'dart:convert'; // 👈 اضافه شد برای پردازش اطلاعات سرور
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http; // 👈 اضافه شد برای بی‌سیم دوربرد
import 'admin_panel_screen.dart';
import '../core/constants.dart';
import '../core/ancient_theme.dart';
import 'game_screen.dart';
import 'chapters_screen.dart';
import 'proverb_levels_screen.dart';
import 'about_screen.dart';
import 'leaderboard_screen.dart';
import 'add_word_screen.dart';
import 'puzzle_screen.dart';
import 'online_lobby_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with TickerProviderStateMixin {
  int totalCoins = 0; // سکه‌های محلی بازی
  int onlineScore = 0; // 🌍 امتیاز نبردهای جهانی (از دیتابیس)
  String phone = ''; // شماره موبایل کاربر
  bool isAdmin = false; // 👑 متغیر تشخیص فرمانده

  bool canClaimDaily = false;
  String playerName = 'در حال دریافت...';
  String playerAvatar = '🛡️';
  bool isBgmEnabled = true;
  bool isSfxEnabled = true;
  bool _isRubikaClaimed = false;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  late AnimationController _chestAnimationController;
  late Animation<double> _chestScaleAnimation;

  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;

  // ⚠️ لینک سرور لیارای خودت
  final String serverUrl = 'https://astoniea-server.liara.run';

  // ==========================================
  // دیتابیس ۴۶ ضرب‌المثل اصیل تاتی دانسفهان
  // ==========================================
  final List<Map<String, String>> proverbsList = [
    {
      "tati": "آوه تا خرینا ن بی صافا نم بیه",
      "fa": "آب تا گل آلود نشود زلال نخواهد شد",
    },
    {
      "tati": "اجه جستی جه معله بروشاش سر بَرش آخور دنِ تِ ما بدی آسی بروش",
      "fa":
          "اگر خواستی این خانه را بفروشی سر درب دروازه‌اش را خراب کن و بساز و بعد بفروش. (چشیدن مزه کار و سختی جهت عبرت‌گیری)",
    },
    {
      "tati": "اجه جستی خاچه بزناش سری بشه جا پیله تپا بزن.",
      "fa":
          "اگر خواستی خاک برسرت بزنی برو از بزرگترین تپه انتخاب کن (بنده هر ناکس نشدن)",
    },
    {
      "tati": "اشتر شون بو آ جردنی خوله بو آشه چام راسته.",
      "fa":
          "به شتر گفتند، گردنت کج است گفت: کجام راسته (صحه گذاری بر نقش ناراست شتر)",
    },
    {
      "tati": "اشتر همیشه خرما نمی‌میزه.",
      "fa": "شتر همیشه خرما نمی‌... (اوضاع همیشه بر وفق مراد نیست)",
    },
    {
      "tati": "ام برینجه جا برینجا فنه دهه تره",
      "fa": "این (پنجره) از آن وضعیت بدتری دارد. (سرو ته یک کرباس بودن)",
    },
    {
      "tati": "انده صنم درم که یاصنم ویرما نمیمینه.",
      "fa": "آنقدر کار مهم دارم که کارهای جزیی را فراموش می‌کنم.",
    },
    {
      "tati": "انگوره انگوره می‌وینیه رنگ اونگوریه.",
      "fa": "انگور انگور را می‌بیند رنگ برمیدارد. (تاثیر متقابل)",
    },
    {
      "tati": "ای ال لا بارج دُ ال لا قوی",
      "fa":
          "مانند طناب یک رشته ضعیف و اگر دو رشته باهم باشد قوی (در هر صورت نمی‌توان به تو تکیه کرد، گاهی از ضعف و گاهی از قدرت گله‌مندی)",
    },
    {
      "tati": "ای سال بوخه نون و تره صد سال بوخه نون و کره",
      "fa":
          "یک سال قناعت کن -نون و تره بخور- صد سال در آسایش – نون و کره- بخور.",
    },
    {
      "tati": "ای وا داره بزه ای گله باد مدیه.",
      "fa": "یک بز گر یک گله را گر می‌کند.",
    },
    {
      "tati": "بزه تا دمش تچون نده ته که هونوم وزه سرش.",
      "fa": "بز ماده تا دم تکان ندهد بز نر با او کاری ندارد.",
    },
    {
      "tati": "بستا مال او خوته ماله خرج موخاره",
      "fa": "گاو سرپا سهم گاو خوابیده را می‌خورد",
    },
    {
      "tati": "بو آشون ن کو، ن کو، بی میش تش تبیله سکو.",
      "fa": "آنقدر گفتند خوب خوب همه را یک مرتبه خراب کرد.",
    },
    {
      "tati": "بولاغ خودش مجو آوش در دَ بی، دستیه آون آنمبه",
      "fa": "چشمه باید خود جوش باشد با ریختن آب جاری نمی‌شود.",
    },
    {
      "tati": "بیچین، اونشو بیچین اوخوسو بیچین.",
      "fa": "درو کن، هر جور که دوست داری بشین یا بخواب.",
    },
    {"tati": "تنه جرما جرم نون آندیه.", "fa": "تنور گرم نان خوب می‌دهد."},
    {
      "tati": "جستم سری دبندم اسبه آخوره، خودی بشش خره سر آخوره.",
      "fa":
          "خواستم تورا سر آخور اسب ببندم، خودت رفتی سر آخور خر (ارزش کسب مقام بالا را نداری)",
    },
    {
      "tati": "جمه بزاستیمون پیلا چروم.",
      "fa": "این را زائیدیم بزرگ کنیم تا به بقیه برسه.",
    },
    {
      "tati": "چرچه هر چی قدقد چری، ای چرخا دا ویشتر نمچریه.",
      "fa":
          "مرغ هرچقدر قدقد کند تنها یک تخم می‌گذارد. (ظرفیت و توان هرکس مشخصه)",
    },
    {
      "tati": "چله چله نموینیه ماجیه ویناش یوزه چو موشه.",
      "fa":
          "اجاق (حاوی آتش) اجاق بغلی را نمی‌بیند خیال می‌کند چوب گردو می‌سوزد. (هرکس وضعیت خودش را می‌بیند، مرغ همسایه غازه)",
    },
    {
      "tati": "چو اوگوراش دزده مرچینه م وزیه.",
      "fa": "چوب برداری گربه‌ی دزد فرار می‌کنه.",
    },
    {
      "tati": "چوپون اگه جوستش بی شت آد نره بزیجه کو متوشه.",
      "fa":
          "چوپان خواسته باشه شیر بده از بزه نر هم شیر می‌دوشد. (انجام کار با هر شرایطی)",
    },
    {
      "tati": "چوتر دروم چوتر دروم",
      "fa": "کبوتر داریم کبوتر داریم. (توانمندی همه یکسان نیست)",
    },
    {
      "tati": "خدا نیا دِرِ ورج نِموخاره",
      "fa": "آن که خدا نگهدارش باشد، گرگ نمی‌خورد",
    },
    {
      "tati": "خره دُمبا بی جیرتِشه ماجه جوه.",
      "fa": "دم خر را گرفته میگه گاوه (انکار کار آشکار)",
    },
    {
      "tati": "خره همی آ خره جلش عوضا وییه.",
      "fa":
          "خر همان خر است پالانش تعویض شده. (در اصل کار تغییری اتفاق نیافتاده است)",
    },
    {
      "tati": "دست دسته موشوره دستی آنجرده دیمه مشوره.",
      "fa": "دست دست را می‌شوید دست دیگه هم صورت را می‌شوید. (یاری متقابل)",
    },
    {
      "tati": "دیمش بینه اشتر جیر پا.",
      "fa": "صورت او - از پررویی - مثل کف پای شتره",
    },
    {
      "tati": "رسن چو تا وعه اشته نرسست.",
      "fa": "ریسمان کوتاه بود به تو نرسید. (نیازی به اظهار نظر جنابعالی نیست)",
    },
    {
      "tati": "زنیش مجواما شو دارش.",
      "fa": "زن می‌خواهد اما شوهر دارش را (انجام کار محال)",
    },
    {
      "tati": "شاس ونه اسبه مزنی، خوناخا آمبیی.",
      "fa": "سگ شاهسون را می‌زنی باهاش طرح دوست می‌بندی.",
    },
    {
      "tati": "شوعه سیاه جو سیاه",
      "fa": "شب سیاه گاو سیاه (رها کردن تیر در تاریکی)",
    },
    {
      "tati": "عالا قاپو ویندنا دروازش پیلا نمچره.",
      "fa":
          "با دیدن عالی قاپو درب خانه اش را بزرگ نمی‌کند. (هر چیز ظرفیت می‌خواهد)",
    },
    {
      "tati": "غیرت خوروزه کو، رفیقی اسبه کو، آوه ا وخردن خره کو، پیشه بیجی.",
      "fa":
          "غیرت را از خروس، وفا را از اسب، و آب خوردن را از خر بیاموز. (حیوانات نماد غیرت، وفا و نحوه آب خوردن)",
    },
    {
      "tati": "قوناق یر، زارو دروارا.",
      "fa":
          "میهمان بخور بچه‌ها حمله کنید و امان ندهید. (حالا که از دست رفتنی است بهتر بچه‌های خودم هم بخورند)",
    },
    {
      "tati": "کر کوره فُرمونا نیه.",
      "fa": "کر از کور حرف شنوی ندارد. (هیچ کس از دیگری حرف شنوی ندارد)",
    },
    {
      "tati": "کی بونوه دو آبی آش یا نمبیییه یا مسوجیه",
      "fa":
          "کدبانو دو تا شود آش یا خام می‌ماند و یا می‌سوزد. (آشپز که دوتا شد...)",
    },
    {"tati": "گوشت جوس تا م شو قصاب ور", "fa": "خواهان گوشت سراغ قصاب می‌رود."},
    {
      "tati": "ماجاوه ب مردو واره بسییست",
      "fa": "گاو مرد و شراکت ما به هم خورد. (علت ارتباط ما از بین رفت)",
    },
    {
      "tati": "مرچینشون بو آ، ج وی درمونه را مشا، خاکش تیه سرش.",
      "fa": "به گربه گفتند مدفوع تو برای درمان درد خوبه آن را مخفی کرد.",
    },
    {
      "tati": "مرچینه خیره پیرش موش نمی‌جیریه.",
      "fa":
          "گربه به خیر پدرش موش نمی‌گیرد. (هیچ کس کاری بدون طمع انجام نمی‌دهد)",
    },
    {
      "tati": "ورجه ترسیا اسبش کوله جرته.",
      "fa": "از ترس گرگ به سگ کولی می‌دهد.",
    },
    {
      "tati": "هر مرو ن م تونه انجیله بو خاری.",
      "fa": "هر پرنده‌ای نمی‌تواند انجیل بخورد. (کار هر بز نیست خرمن کوفتن)",
    },
    {
      "tati": "همه موخارند سیرا ویننه آما موخاروم تمونا ویننه.",
      "fa":
          "همه می‌خورند سیر بشند ما می‌خوریم تا غذا تمام بشه. (کار ما اصولی نیست)",
    },
    {
      "tati": "سنجه بزناش سنجه سر خوردش بر میا",
      "fa":
          "سنگ را روی سنگ بزنی، سنگ ریزه بوجود می‌آید. (با تلاش نتیجه‌ای به دست می‌آید)",
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkRubikaStatus();
    _loadSettingsAndData();
    _fetchProfileData(); // 📡 دریافت اطلاعات آنلاین پروفایل
    _showNewYearGreeting();

    _chestAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _chestScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _chestAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _heartbeatAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );
  }

  // ==========================================
  // 📡 ارتباط با سرور برای پروفایل و تغییر نام
  // ==========================================
  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    // 👈 بسیار مهم: کلید رو بکن 'userPhone' که با بقیه کدها هماهنگ بشه
    phone = prefs.getString('userPhone') ?? '';

    if (phone.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/user/profile/$phone'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          playerName = data['username'] ?? playerName;
          onlineScore = data['score'] ?? 0;
          // سرور چک می‌کنه اگه role شما admin بود، این متغیر true می‌شه
          isAdmin = data['role'] == 'admin';
        });
      }
    } catch (e) {
      debugPrint("خطا در دریافت پروفایل: $e");
    }
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: playerName,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.epicGold, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'تغییر نام فرماندهی',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Morvarid', color: AppColors.epicGold),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white, fontFamily: 'Morvarid'),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'نام جدید را وارد کنید',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black45,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'لغو',
              style: TextStyle(color: Colors.grey, fontFamily: 'Morvarid'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _updateNameOnServer(nameController.text);
            },
            child: const Text(
              'ذخیره',
              style: TextStyle(color: Colors.white, fontFamily: 'Morvarid'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateNameOnServer(String newName) async {
    if (newName.trim().isEmpty || phone.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/user/update-name'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'newName': newName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          playerName = data['username'];
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('playerName', playerName);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'نام با موفقیت در پایگاه ابری تغییر کرد!',
              style: TextStyle(fontFamily: 'Morvarid'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطا در ارتباط با سرور',
            style: TextStyle(fontFamily: 'Morvarid'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkRubikaStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRubikaClaimed = prefs.getBool('isRubikaClaimed') ?? false;
    });
  }

  Future<void> _joinRubikaAndClaimReward() async {
    final Uri url = Uri.parse('https://rubika.ir/Astoniea');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!_isRubikaClaimed) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          totalCoins += 100;
          _isRubikaClaimed = true;
        });
        await prefs.setInt('totalCoins', totalCoins);
        await prefs.setBool('isRubikaClaimed', true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.monetization_on, color: Colors.amber, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '۱۰۰ سکه طلا بابت پیوستن به ارتش اَستُونیه واریز شد! ⚔️',
                    style: TextStyle(
                      fontFamily: 'Piramooz',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
        _playSound('sword.mp3');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطا در باز کردن لینک روبیکا!',
            style: TextStyle(fontFamily: 'Piramooz'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSettingsAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalCoins = prefs.getInt('totalCoins') ?? 100;
      isBgmEnabled = prefs.getBool('isBgmEnabled') ?? true;
      isSfxEnabled = prefs.getBool('isSfxEnabled') ?? true;
      playerAvatar = prefs.getString('playerAvatar') ?? '🛡️';
    });

    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    if (isBgmEnabled) {
      _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
    }

    String lastClaimDate = prefs.getString('lastDailyReward') ?? '';
    String today = DateTime.now().toIso8601String().split('T')[0];

    if (lastClaimDate != today) {
      setState(() => canClaimDaily = true);
    } else {
      _chestAnimationController.stop();
    }
  }

  void _playSound(String fileName) async {
    if (isSfxEnabled) {
      await _sfxPlayer.play(AssetSource('audio/$fileName'));
    }
  }

  Future<void> _claimDailyReward() async {
    if (!canClaimDaily) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'امروز غنائم را جمع‌آوری کردی! فردا برگرد ⏳',
            style: TextStyle(fontFamily: 'Piramooz', fontSize: 16),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int rewardCoins = 20 + Random().nextInt(31);
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      totalCoins += rewardCoins;
      canClaimDaily = false;
    });

    await prefs.setInt('totalCoins', totalCoins);
    await prefs.setString('lastDailyReward', today);
    _chestAnimationController.stop();
    _playSound('sword.mp3');

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.amber, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'غنائم روزانه! 🎁',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.amber,
            fontFamily: 'Piramooz',
            fontSize: 32,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 80),
            const SizedBox(height: 15),
            Text(
              '+$rewardCoins سکه به خزانه‌ات اضافه شد!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontFamily: 'Piramooz',
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bloodRed,
              side: const BorderSide(color: AppColors.epicGold),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ایول! ⚔️',
              style: TextStyle(
                fontFamily: 'Piramooz',
                fontSize: 20,
                color: AppColors.epicGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewYearGreeting() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeenGreeting = prefs.getBool('hasSeenNewYear1405') ?? false;

    if (!hasSeenGreeting) {
      await prefs.setBool('hasSeenNewYear1405', true);
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        _playSound('bubble.mp3');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🎊🌸', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'سال ۱۴۰۵ مبارک!',
                        style: TextStyle(
                          fontFamily: 'Piramooz',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 54, 42, 1),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'فرمانده، فرا رسیدن سال نو بر شما و ارتش اَستُونیه خجسته باد! ⚔️',
                        style: TextStyle(
                          fontFamily: 'Piramooz',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color.fromARGB(
              255,
              2,
              136,
              9,
            ).withOpacity(0.95),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(
                color: Color.fromARGB(255, 172, 140, 32),
                width: 2,
              ),
            ),
            duration: const Duration(seconds: 6),
            elevation: 10,
          ),
        );
      });
    }
  }

  void _showWisdomScroll() {
    final now = DateTime.now();
    int daysPassed = now.difference(DateTime(2024, 1, 1)).inDays;
    int index = daysPassed % proverbsList.length;
    final proverb = proverbsList[index];

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFFF4EED7),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF8B5A2B), width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Column(
            children: [
              Icon(Icons.history_edu, color: Color(0xFF8B5A2B), size: 50),
              SizedBox(height: 10),
              Text(
                'پندِ امروز',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5A0000),
                  fontFamily: 'Piramooz',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ضرب‌المثل اصیل تاتی:',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                proverb['tati']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Piramooz',
                  height: 1.5,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15.0),
                child: Divider(color: Color(0xFF8B5A2B), thickness: 2),
              ),
              const Text(
                'معنی و مفهوم:',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                proverb['fa']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5A0000),
                  fontSize: 20,
                  fontFamily: 'Piramooz',
                  height: 1.5,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5A2B),
                side: const BorderSide(color: Color(0xFF5A0000), width: 2),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                _playSound('bubble.mp3');
                Navigator.pop(context);
              },
              child: const Text(
                'پند گرفتم 📜',
                style: TextStyle(
                  fontFamily: 'Piramooz',
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chestAnimationController.dispose();
    _heartbeatController.dispose();
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.darkBackground,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'تنظیمات نبرد ⚙️',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Piramooz',
                  fontSize: 28,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text(
                      'موسیقی حماسی',
                      style: TextStyle(
                        fontFamily: 'Piramooz',
                        color: AppColors.epicGold,
                        fontSize: 17,
                      ),
                    ),
                    activeColor: AppColors.bloodRed,
                    value: isBgmEnabled,
                    onChanged: (bool value) async {
                      final prefs = await SharedPreferences.getInstance();
                      setStateDialog(() => isBgmEnabled = value);
                      setState(() => isBgmEnabled = value);
                      prefs.setBool('isBgmEnabled', value);
                      if (value) {
                        _bgmPlayer.play(AssetSource('audio/bgm.mp3'));
                      } else {
                        _bgmPlayer.pause();
                      }
                    },
                  ),
                  const Divider(color: Colors.grey),
                  SwitchListTile(
                    title: const Text(
                      'صدای شمشیر',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Piramooz',
                        color: AppColors.epicGold,
                        fontSize: 18,
                      ),
                    ),
                    activeColor: AppColors.bloodRed,
                    value: isSfxEnabled,
                    onChanged: (bool value) async {
                      final prefs = await SharedPreferences.getInstance();
                      setStateDialog(() => isSfxEnabled = value);
                      setState(() => isSfxEnabled = value);
                      prefs.setBool('isSfxEnabled', value);
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading: const Icon(
                      Icons.workspace_premium,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
                    title: const Text(
                      'درباره تیم سازنده',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Piramooz',
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _playSound('bubble.mp3');
                      Navigator.pop(context);
                      _showTeamDialog();
                    },
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bloodRed,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'بستن',
                    style: TextStyle(
                      fontFamily: 'Piramooz',
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGameModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.epicGold, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'انتخاب نوع نبرد',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.epicGold,
            fontFamily: 'Piramooz',
            fontSize: 32,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'می‌خواهی چطور مهارتت را بسنجی؟',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.paperWhite, fontSize: 16),
            ),
            const SizedBox(height: 30),
            _buildDialogButton(
              context,
              title: 'نبرد مرحله‌ای (۴ گزینه‌ای) 🗺️',
              color: AppColors.bloodRed,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createFadeRoute(const ChaptersScreen(gameMode: 'quiz')),
                ).then((_) => _loadSettingsAndData());
              },
            ),
            const SizedBox(height: 15),
            _buildDialogButton(
              context,
              title: 'معمای کلمات (پازل حروف) 🧩',
              color: const Color(0xFF1E5631),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createFadeRoute(const ChaptersScreen(gameMode: 'puzzle')),
                ).then((_) => _loadSettingsAndData());
              },
            ),
            const SizedBox(height: 15),
            _buildDialogButton(
              context,
              title: 'نبرد خردمندان (ضرب‌المثل) 📜',
              color: Colors.purple.shade900,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  _createFadeRoute(const ProverbLevelsScreen()),
                ).then((_) => _loadSettingsAndData());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _playSound('bubble.mp3');
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.epicGold.withOpacity(0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Piramooz',
              fontSize: 22,
              color: AppColors.epicGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineBattleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _playSound('bubble.mp3');
          Navigator.push(context, _createFadeRoute(const OnlineLobbyScreen()));
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.lightBlueAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'نبرد آنلاین جهانی 🌍',
                style: TextStyle(
                  fontFamily: 'Piramooz',
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AncientIslamicTheme(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  // ==========================================
                  // 📊 کادر اطلاعات سرباز (نام، ویرایش و امتیازات)
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.epicGold.withOpacity(0.8),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  playerAvatar,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              playerName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Piramooz',
                                                color: AppColors.paperWhite,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _showEditNameDialog,
                                            child: const Icon(
                                              Icons.edit,
                                              color: AppColors.epicGold,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '🏆 امتیاز جهانی: $onlineScore',
                                        style: const TextStyle(
                                          fontFamily: 'Piramooz',
                                          color: Colors.amberAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // سکه‌های محلی بازی
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.epicGold,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: AppColors.epicGold,
                                size: 22,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$totalCoins',
                                style: const TextStyle(
                                  fontFamily: 'Piramooz',
                                  color: AppColors.epicGold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // دکمه‌های بالا (تنظیمات، صندوقچه، پندها)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.grey,
                            size: 30,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _playSound('bubble.mp3');
                            _showSettingsDialog();
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _playSound('bubble.mp3');
                            _claimDailyReward();
                          },
                          child: ScaleTransition(
                            scale: _chestScaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: canClaimDaily
                                    ? Colors.amber.withOpacity(0.2)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                boxShadow: canClaimDaily
                                    ? [
                                        const BoxShadow(
                                          color: Colors.amber,
                                          blurRadius: 15,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                canClaimDaily
                                    ? Icons.card_giftcard
                                    : Icons.lock_outline,
                                color: canClaimDaily
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.history_edu,
                            color: Color(0xFFE3D5B8),
                            size: 30,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _playSound('bubble.mp3');
                            _showWisdomScroll();
                          },
                        ),
                      ],
                    ),
                  ),

                  if (!_isRubikaClaimed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: InkWell(
                        onTap: _joinRubikaAndClaimReward,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF300030), Color(0xFF1A001A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.epicGold.withOpacity(0.8),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.epicGold.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.transparent,
                                    highlightColor: Colors.white.withOpacity(
                                      0.1,
                                    ),
                                    period: const Duration(seconds: 3),
                                    child: Container(color: Colors.white),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.epicGold,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.campaign,
                                        color: AppColors.epicGold,
                                        size: 35,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'پیکِ خبررسان اَستُونیه',
                                            style: TextStyle(
                                              fontFamily: 'Piramooz',
                                              fontSize: 20,
                                              color: AppColors.paperWhite,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: const [
                                              Text(
                                                'عضویت در روبیکا = ',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Icon(
                                                Icons.monetization_on,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              Text(
                                                ' ۱۰۰ سکه',
                                                style: TextStyle(
                                                  fontFamily: 'Piramooz',
                                                  color: Colors.amber,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppColors.epicGold,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 25),

                  Image.asset(
                    'assets/images/shield.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.security,
                      color: AppColors.epicGold,
                      size: 100,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'اَستُونیه',
                    style: TextStyle(
                      fontFamily: 'Piramooz',
                      color: AppColors.epicGold,
                      fontSize: 45,
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
                  const SizedBox(height: 5),
                  const Text(
                    'آزمون و آموزش زبان اصیل تاتی',
                    style: TextStyle(
                      color: AppColors.paperWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 35),

                  ScaleTransition(
                    scale: _heartbeatAnimation,
                    child: _buildMenuButton(
                      context,
                      title: 'شروع نبرد ⚔️',
                      isPrimary: true,
                      onTap: () => _showGameModeDialog(context),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // دکمه نبرد آنلاین
                  _buildOnlineBattleButton(),

                  // 👑 دکمه مخفی فرماندهی (فقط برای ادمین نمایش داده می‌شود)
                  if (isAdmin) ...[
                    const SizedBox(height: 15),
                    _buildMenuButton(
                      context,
                      title: 'ورود به اتاق فرماندهی 👑',
                      isPrimary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          _createFadeRoute(const AdminPanelScreen()),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 15),
                  _buildMenuButton(
                    context,
                    title: 'تالار افتخارات 🏆',
                    isPrimary: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        _createFadeRoute(const LeaderboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    context,
                    title: 'درباره دانسفهان 🏰',
                    isPrimary: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        _createFadeRoute(const AboutScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildMenuButton(
                    context,
                    title: 'ارسال کلمه جدید ✉️',
                    isPrimary: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        _createFadeRoute(const AddWordScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'تقدیم به مردم اصیل دانسفهان',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'طراح و توسعه دهنده: صادق رامندی‌نسب',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _playSound('bubble.mp3');
          onTap();
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPrimary
                  ? [AppColors.bloodRed, const Color(0xFF5A0000)]
                  : [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.epicGold.withOpacity(isPrimary ? 1.0 : 0.7),
              width: isPrimary ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Piramooz',
                fontSize: 24,
                color: isPrimary ? AppColors.epicGold : AppColors.paperWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  // ===============================================
  // 🤝 دیالوگ تیم سازنده و بخش حمایت مالی
  // ===============================================
  void _showTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.epicGold, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Column(
          children: [
            Icon(Icons.rocket_launch, color: Colors.blueAccent, size: 40),
            SizedBox(height: 10),
            Text(
              'گروه دانش‌بنیان فدک',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Piramooz',
                fontSize: 26,
              ),
            ),
            Text(
              'دانسفهان',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueAccent,
                fontFamily: 'Piramooz',
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.person, color: AppColors.epicGold),
                      SizedBox(width: 10),
                      Text(
                        'توسعه‌دهنده و مدیر:',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'صادق رامنـدی‌نسـب',
                style: TextStyle(
                  color: AppColors.epicGold,
                  fontFamily: 'Piramooz',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'همکاران: علیرضا لامعی - ابوالفضل انصاری',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Piramooz',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 25),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialIcon(
                    Icons.phone,
                    Colors.green,
                    () => _launchURL('tel:09211103624'),
                  ),
                  _buildSocialIcon(
                    Icons.telegram,
                    Colors.blue,
                    () => _launchURL('https://t.me/sad_ra_non'),
                  ),
                  _buildSocialIcon(
                    Icons.email,
                    Colors.redAccent,
                    () => _launchURL('mailto:sarbazmahdi1440@gmail.com'),
                  ),
                  _buildSocialIcon(
                    Icons.link,
                    Colors.purpleAccent,
                    () => _launchURL('https://rubika.ir/sad_ra_non'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '۰۹۲۱۱۱۰۳۶۲۴',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bloodRed,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'بستن',
              style: TextStyle(
                fontFamily: 'Piramooz',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'نمی‌توان لینک را باز کرد!',
            style: TextStyle(fontFamily: 'Piramooz'),
          ),
        ),
      );
    }
  }
}
