import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../core/constants.dart';

class ProverbScreen extends StatefulWidget {
  final int stageNumber; // شماره مرحله
  const ProverbScreen({Key? key, required this.stageNumber}) : super(key: key);

  // =======================================================
  // 📚 گنجینه ضرب‌المثل‌های اصیل تاتی دانسفهان
  // =======================================================
  static final List<Map<String, dynamic>> proverbsData = [
    {
      "text": "آوه تا [...] ن بی صافا نم بیه",
      "answer": "خرینا",
      "wrong": ["پاک", "جارو", "لوش"],
      "fa": "آب تا گل آلود نشود زلال نخواهد شد.",
    },
    {
      "text": "اجه جستی جه معله بروشاش سر [...] آخور دنِ تِ ما بدی آسی بروش",
      "answer": "بَرش",
      "wrong": ["دیفار", "بوم", "پنجره"],
      "fa":
          "اگر خواستی این خانه را بفروشی سر درب دروازه‌اش را خراب کن و بساز (چشیدن سختی).",
    },
    {
      "text": "اجه جستی [...] بزناش سری بشه جا پیله تپا بزن",
      "answer": "خاچه",
      "wrong": ["سنگ", "چوب", "آو"],
      "fa":
          "اگر خواستی خاک بر سرت بزنی از بزرگترین تپه انتخاب کن (بنده هر ناکس نشدن).",
    },
    {
      "text": "[...] شون بو آ جردنی خوله بو آشه چام راسته",
      "answer": "اشتر",
      "wrong": ["اسب", "قاطر", "گاو"],
      "fa": "به شتر گفتند گردنت کج است، گفت کجام راسته؟!",
    },
    {
      "text": "اشتر همیشه [...] نمی‌میزه",
      "answer": "خرما",
      "wrong": ["جو", "گندم", "علف"],
      "fa": "شتر همیشه خرما نمی‌دهد (اوضاع همیشه بر وفق مراد نیست).",
    },
    {
      "text": "ام برینجه جا [...] فنه دهه تره",
      "answer": "برینجا",
      "wrong": ["در", "سقف", "حیاط"],
      "fa": "این از آن وضعیت بدتری دارد (سر و ته یک کرباس بودن).",
    },
    {
      "text": "انده صنم درم که [...] ویرما نمیمینه",
      "answer": "یاصنم",
      "wrong": ["کارم", "بارم", "پولم"],
      "fa": "آنقدر کار مهم دارم که کارهای جزیی را فراموش می‌کنم.",
    },
    {
      "text": "[...] انگوره می‌وینیه رنگ اونگوریه",
      "answer": "انگوره",
      "wrong": ["سیبه", "اناره", "خربزه"],
      "fa": "انگور انگور را می‌بیند رنگ برمی‌دارد (تاثیر متقابل).",
    },
    {
      "text": "ای ال لا [...] دُ ال لا قوی",
      "answer": "بارج",
      "wrong": ["سفت", "محکم", "دراز"],
      "fa":
          "مثل طناب یک رشته ضعیف است و دو رشته قوی (در هر صورت نمی‌توان به تو تکیه کرد).",
    },
    {
      "text": "ای سال بوخه نون و [...] صد سال بوخه نون و کره",
      "answer": "تره",
      "wrong": ["ماست", "پنیر", "گوشت"],
      "fa": "یک سال قناعت کن (نون و تره)، صد سال در آسایش باش (نون و کره).",
    },
    {
      "text": "ای وا داره [...] ای گله باد مدیه",
      "answer": "بزه",
      "wrong": ["گوسفند", "گاو", "سگ"],
      "fa": "یک بز گر یک گله را گر می‌کند.",
    },
    {
      "text": "[...] مال او خوته ماله خرج موخاره",
      "answer": "بستا",
      "wrong": ["پیر", "جوان", "مریض"],
      "fa": "گاو سرپا سهم گاو خوابیده را می‌خورد.",
    },
    {
      "text": "بو آشون ن کو، ن کو، بی میش تش [...] سکو",
      "answer": "تبیله",
      "wrong": ["خونه", "حیاط", "دشت"],
      "fa": "آنقدر گفتند خوب خوب، همه را یک مرتبه خراب کرد (طویله کرد).",
    },
    {
      "text": "[...] خودش مجو آوش در دَ بی، دستیه آون آنمبه",
      "answer": "بولاغ",
      "wrong": ["چاه", "رود", "دریا"],
      "fa": "چشمه باید خودجوش باشد، با ریختن آب جاری نمی‌شود.",
    },
    {
      "text": "بیچین، اونشو بیچین [...] بیچین",
      "answer": "اوخوسو",
      "wrong": ["بنشین", "وایسا", "بگرد"],
      "fa": "درو کن، هر جور که دوست داری بنشین یا بخواب.",
    },
    {
      "text": "[...] جرما جرم نون آندیه",
      "answer": "تنه",
      "wrong": ["دیگ", "ساج", "چاله"],
      "fa": "تنور گرم نان خوب می‌دهد.",
    },
    {
      "text": "جستم سری دبندم [...] آخوره، خودی بشش خره سر آخوره",
      "answer": "اسبه",
      "wrong": ["گاوه", "قاطره", "شتره"],
      "fa":
          "خواستم تو را سر آخور اسب ببندم، خودت رفتی سر آخور خر (لیاقت نداشتی).",
    },
    {
      "text": "جمه بزاستیمون [...] چروم",
      "answer": "پیلا",
      "wrong": ["کوچیک", "قشنگ", "زشت"],
      "fa": "این را زائیدیم بزرگ کنیم تا به بقیه برسه.",
    },
    {
      "text": "[...] هر چی قدقد چری، ای چرخا دا ویشتر نمچریه",
      "answer": "چرچه",
      "wrong": ["کبوتر", "غاز", "اردک"],
      "fa": "مرغ هرچقدر قدقد کند تنها یک تخم می‌گذارد (ظرفیت هرکس مشخص است).",
    },
    {
      "text": "[...] چله نموینیه ماجیه ویناش یوزه چو موشه",
      "answer": "چله",
      "wrong": ["تنور", "بخاری", "آتیش"],
      "fa":
          "اجاق، اجاق بغلی را نمی‌بیند خیال می‌کند چوب گردو می‌سوزد (مرغ همسایه غازه).",
    },
    {
      "text": "چو اوگوراش دزده [...] م وزیه",
      "answer": "مرچینه",
      "wrong": ["سگه", "موشه", "گرگه"],
      "fa": "چوب برداری گربه‌ی دزد فرار می‌کنه.",
    },
    {
      "text": "چوپون اگه جوستش بی شت آد [...] بزیجه کو متوشه",
      "answer": "نره",
      "wrong": ["ماده", "پیر", "کوچیک"],
      "fa":
          "چوپان خواسته باشه شیر بده از بز نر هم شیر می‌دوشد (انجام کار با هر شرایطی).",
    },
    {
      "text": "[...] دروم چوتر دروم",
      "answer": "چوتر",
      "wrong": ["مرغ", "خروس", "گنجشک"],
      "fa": "کبوتر داریم کبوتر داریم (توانمندی همه یکسان نیست).",
    },
    {
      "text": "خدا نیا دِرِ [...] نِموخاره",
      "answer": "ورج",
      "wrong": ["سگ", "خرس", "شغال"],
      "fa": "آن که خدا نگهدارش باشد، گرگ نمی‌خورد.",
    },
    {
      "text": "[...] دُمبا بی جیرتِشه ماجه جوه",
      "answer": "خره",
      "wrong": ["اسبه", "شتره", "سگه"],
      "fa": "دم خر را گرفته میگه گاوه (انکار کار آشکار).",
    },
    {
      "text": "خره همی آ خره [...] عوضا وییه",
      "answer": "جلش",
      "wrong": ["بارش", "افسارش", "سمش"],
      "fa": "خر همان خر است پالانش تعویض شده (در اصل تغییری نکرده).",
    },
    {
      "text": "[...] دسته موشوره دستی آنجرده دیمه مشوره",
      "answer": "دست",
      "wrong": ["پا", "سر", "چشم"],
      "fa": "دست دست را می‌شوید، دست دیگه هم صورت را می‌شوید (یاری متقابل).",
    },
    {
      "text": "[...] بینه اشتر جیر پا",
      "answer": "دیمش",
      "wrong": ["دستش", "پاش", "چشمش"],
      "fa": "صورت او از پررویی مثل کف پای شتره.",
    },
    {
      "text": "[...] چو تا وعه اشته نرسست",
      "answer": "رسن",
      "wrong": ["چوب", "سیم", "نخ"],
      "fa": "ریسمان کوتاه بود به تو نرسید (نیازی به اظهار نظر جنابعالی نیست).",
    },
    {
      "text": "شاس ونه [...] مزنی، خوناخا آمبیی",
      "answer": "اسبه",
      "wrong": ["گاوه", "خره", "بزه"],
      "fa": "سگ (اسبه) شاهسون را می‌زنی باهاش طرح دوست می‌بندی؟!",
    },
    {
      "text": "[...] سیاه جو سیاه",
      "answer": "شوعه",
      "wrong": ["روزه", "ظهره", "غروب"],
      "fa": "شب سیاه گاو سیاه (رها کردن تیر در تاریکی).",
    },
    {
      "text": "عالا قاپو ویندنا دروازش [...] نمچره",
      "answer": "پیلا",
      "wrong": ["کوچیک", "دراز", "پهن"],
      "fa":
          "با دیدن عالی قاپو درب خانه‌اش را بزرگ نمی‌کند (هر چیز ظرفیت می‌خواهد).",
    },
    {
      "text": "غیرت خوروزه کو، رفیقی اسبه کو، آوه ا وخردن [...] کو، پیشه بیجی",
      "answer": "خره",
      "wrong": ["گاوه", "بزه", "گوسفنده"],
      "fa": "غیرت را از خروس، وفا را از سگ و آب خوردن را از خر بیاموز.",
    },
    {
      "text": "[...] یر، زارو دروارا",
      "answer": "قوناق",
      "wrong": ["همسایه", "فامیل", "غریبه"],
      "fa":
          "میهمان بخور، بچه‌ها حمله کنید (حالا که از دست رفتنی است بهتر بچه‌های خودم بخورند).",
    },
    {
      "text": "[...] کوره فُرمونا نیه",
      "answer": "کر",
      "wrong": ["لال", "شل", "گیج"],
      "fa": "کر از کور حرف شنوی ندارد.",
    },
    {
      "text": "[...] دو آبی آش یا نمبیییه یا مسوجیه",
      "answer": "کی بونوه",
      "wrong": ["آشپز", "نانوا", "قصاب"],
      "fa": "کدبانو دو تا شود آش یا خام می‌ماند و یا می‌سوزد.",
    },
    {
      "text": "[...] جوس تا م شو قصاب ور",
      "answer": "گوشت",
      "wrong": ["پوست", "استخوان", "چربی"],
      "fa": "خواهان گوشت سراغ قصاب می‌رود.",
    },
    {
      "text": "[...] ب مردو واره بسییست",
      "answer": "ماجاوه",
      "wrong": ["اسبه", "خره", "بزه"],
      "fa": "گاو مرد و شراکت ما به هم خورد.",
    },
    {
      "text": "[...] بو آ، ج وی درمونه را مشا، خاکش تیه سرش",
      "answer": "مرچینشون",
      "wrong": ["سگشون", "خرشون", "موششون"],
      "fa": "به گربه گفتند مدفوع تو برای درمان خوبه، آن را مخفی کرد.",
    },
    {
      "text": "[...] خیره پیرش موش نمی‌جیریه",
      "answer": "مرچینه",
      "wrong": ["اسبه", "سگه", "روباه"],
      "fa":
          "گربه به خیر پدرش موش نمی‌گیرد (هیچ کس کاری بدون طمع انجام نمی‌دهد).",
    },
    {
      "text": "[...] ترسیا اسبش کوله جرته",
      "answer": "ورجه",
      "wrong": ["خرس", "شغال", "پلنگ"],
      "fa": "از ترس گرگ به سگ کولی می‌دهد.",
    },
    {
      "text": "هر [...] ن م تونه انجیله بو خاری",
      "answer": "مرو",
      "wrong": ["چرچه", "کلاغ", "عقاب"],
      "fa": "هر پرنده‌ای نمی‌تواند انجیر بخورد (کار هر بز نیست خرمن کوفتن).",
    },
    {
      "text": "همه موخارند [...] ویننه آما موخاروم تمونا ویننه",
      "answer": "سیرا",
      "wrong": ["گشنه", "تشنه", "خسته"],
      "fa": "همه می‌خورند سیر بشند ما می‌خوریم تا غذا تمام بشه.",
    },
    {
      "text": "[...] بزناش سنجه سر خوردش بر میا",
      "answer": "سنجه",
      "wrong": ["چوب", "آهن", "شیشه"],
      "fa":
          "سنگ را روی سنگ بزنی، سنگ ریزه بوجود می‌آید (با تلاش نتیجه‌ای به دست می‌آید).",
    },
  ];

  @override
  State<ProverbScreen> createState() => _ProverbScreenState();
}

class _ProverbScreenState extends State<ProverbScreen>
    with TickerProviderStateMixin {
  int totalCoins = 0;
  bool isSfxEnabled = true;

  // فقط تعداد اشتباهات رو برای محاسبه ستاره نگه می‌داریم
  int wrongAttempts = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;

  late AnimationController _timerController;

  late Map<String, dynamic> currentProverb;
  List<String> currentOptions = [];
  bool isAnswered = false;
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _loadWallet();
    _setupStage();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _timerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..addListener(() {
            setState(() {});
            if (_timerController.status == AnimationStatus.completed) {
              _onTimeUp();
            }
          });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.stageNumber <= 3) {
        _showEntryWarning();
      } else {
        _timerController.forward();
      }
    });
  }

  void _setupStage() {
    int dataIndex =
        (widget.stageNumber - 1) % ProverbScreen.proverbsData.length;
    currentProverb = ProverbScreen.proverbsData[dataIndex];

    currentOptions = [currentProverb["answer"], ...currentProverb["wrong"]];
    currentOptions.shuffle();

    setState(() {
      isAnswered = false;
      selectedAnswer = null;
      wrongAttempts = 0;
    });
  }

  void _showEntryWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          '⚠️ تالار خردمندان',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.orange,
            fontFamily: 'Piramooz',
            fontSize: 26,
          ),
        ),
        content: const Text(
          'زمان شما محدود است! (۲۰ ثانیه)\n\nپاسخ اشتباه یا اتمام زمان = کسر ۱۰ سکه\n\nآیا آماده‌ای؟',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Piramooz',
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade900,
            ),
            onPressed: () {
              Navigator.pop(context);
              _timerController.forward();
            },
            child: const Text(
              'شروع کارزار ⚔️',
              style: TextStyle(
                fontFamily: 'Piramooz',
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTimeUp() {
    if (isAnswered) return;
    HapticFeedback.heavyImpact();
    _playSound('shield.mp3');
    setState(() {
      wrongAttempts++;
    });

    // کسر مستقیم از کیف پول اصلی
    _updateWallet(-10);
    _showSnackBarMessage(false, 'زمان تمام شد! ۱۰ سکه کسر شد ⏳');

    _timerController.reset();
    _timerController.forward();
  }

  void _checkAnswer(String selectedOption) async {
    if (isAnswered) return;

    HapticFeedback.selectionClick();
    _timerController.stop();
    bool isCorrect = selectedOption == currentProverb["answer"];

    setState(() {
      isAnswered = true;
      selectedAnswer = selectedOption;
      if (!isCorrect) {
        wrongAttempts++;
      }
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
      _playSound('sword.mp3');
      _confettiController.play();
      _processVictory();
    } else {
      HapticFeedback.heavyImpact();
      _playSound('shield.mp3');

      // جریمه مستقیم از کیف پول
      _updateWallet(-10);
      _showSnackBarMessage(false, 'اشتباه بود! ۱۰ سکه از دست دادی ❌');

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            isAnswered = false;
            selectedAnswer = null;
          });
          _timerController.reset();
          _timerController.forward();
        }
      });
    }
  }

  void _processVictory() async {
    int stars = 3;
    if (wrongAttempts == 1) stars = 2;
    if (wrongAttempts >= 2) stars = 1;

    int rewardCoins = stars * 15;

    final prefs = await SharedPreferences.getInstance();

    int currentUnlocked = prefs.getInt('unlockedProverbLevel') ?? 1;
    if (widget.stageNumber >= currentUnlocked) {
      _updateWallet(rewardCoins);
      await prefs.setInt('unlockedProverbLevel', widget.stageNumber + 1);
    }

    int previousStars =
        prefs.getInt('proverb_stars_l${widget.stageNumber}') ?? 0;
    if (stars > previousStars) {
      await prefs.setInt('proverb_stars_l${widget.stageNumber}', stars);
    }

    _showPronunciationDialog(rewardCoins, stars);
  }

  void _showSnackBarMessage(bool isCorrect, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Piramooz',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isCorrect
            ? Colors.green.shade800
            : Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _showPronunciationDialog(int rewardCoins, int stars) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.greenAccent, width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'خردمندانه بود! 📜',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'Piramooz',
            fontSize: 32,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              rewardCoins > 0
                  ? 'موفق شدی! (+$rewardCoins سکه)'
                  : 'مرحله تکراری (بدون جایزه)',
              style: TextStyle(
                color: rewardCoins > 0 ? Colors.white70 : Colors.orangeAccent,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              currentProverb["text"].replaceAll(
                "[...]",
                currentProverb["answer"],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.epicGold,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Piramooz',
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(color: Colors.greenAccent),
            ),
            Text(
              'معنی: ${currentProverb["fa"]}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
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
              side: const BorderSide(color: AppColors.epicGold, width: 1.5),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              _playSound('bubble.mp3');
              Navigator.pop(context);

              if (widget.stageNumber < ProverbScreen.proverbsData.length) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProverbScreen(stageNumber: widget.stageNumber + 1),
                  ),
                );
              } else {
                _showSnackBarMessage(
                  true,
                  'تبریک! تمام طومارها را تمام کردید 🏆',
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'مرحله بعدی ⏭️',
              style: TextStyle(
                fontFamily: 'Piramooz',
                fontSize: 20,
                color: AppColors.epicGold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _playSound('bubble.mp3');
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'نقشه مراحل',
              style: TextStyle(fontFamily: 'Piramooz', color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadWallet() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalCoins = prefs.getInt('totalCoins') ?? 100;
      isSfxEnabled = prefs.getBool('isSfxEnabled') ?? true;
    });
  }

  Future<void> _updateWallet(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalCoins += amount;
      if (totalCoins < 0) totalCoins = 0;
    });
    await prefs.setInt('totalCoins', totalCoins);
  }

  void _playSound(String fileName) async {
    if (isSfxEnabled) {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    }
  }

  List<Color> _getButtonColors(String option) {
    if (!isAnswered) return [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)];

    if (option == selectedAnswer) {
      if (selectedAnswer == currentProverb["answer"]) {
        return [Colors.green.shade700, Colors.green.shade900];
      } else {
        return [Colors.red.shade700, Colors.red.shade900];
      }
    }

    return [const Color(0xFF3A3A3A), const Color(0xFF1E1E1E)];
  }

  @override
  void dispose() {
    _timerController.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayProverb = currentProverb["text"].replaceAll(
      "[...]",
      " ....... ",
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF141414), Color(0xFF2A2A2A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.epicGold,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                          'مرحله ${widget.stageNumber} 📜',
                          style: const TextStyle(
                            fontFamily: 'Piramooz',
                            color: AppColors.epicGold,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // نوار نمایش سکه کل
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.epicGold,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: AppColors.epicGold,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$totalCoins سکه',
                                style: const TextStyle(
                                  fontFamily: 'Piramooz',
                                  fontSize: 22,
                                  color: AppColors.epicGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: 1.0 - _timerController.value,
                        minHeight: 10,
                        backgroundColor: Colors.white10,
                        color: (1.0 - _timerController.value) > 0.5
                            ? Colors.greenAccent
                            : ((1.0 - _timerController.value) > 0.2
                                  ? Colors.orange
                                  : Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 30,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4EED7),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFF8B5A2B),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.epicGold.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.history_edu,
                                    color: Color(0xFF8B5A2B),
                                    size: 40,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    displayProverb,
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontFamily: 'Piramooz',
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF5A0000),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 15.0,
                                    ),
                                    child: Divider(
                                      color: Color(0xFF8B5A2B),
                                      thickness: 2,
                                    ),
                                  ),
                                  Text(
                                    currentProverb["fa"],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Piramooz',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),

                            ...currentOptions.map((option) {
                              List<Color> buttonColors = _getButtonColors(
                                option,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: InkWell(
                                  onTap: () {
                                    if (!isAnswered) _checkAnswer(option);
                                  },
                                  borderRadius: BorderRadius.circular(15),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: buttonColors,
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color:
                                            isAnswered &&
                                                option ==
                                                    currentProverb["answer"]
                                            ? Colors.greenAccent
                                            : AppColors.epicGold.withOpacity(
                                                0.7,
                                              ),
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
                                        option,
                                        style: const TextStyle(
                                          fontFamily: 'Piramooz',
                                          fontSize: 24,
                                          color: AppColors.paperWhite,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
