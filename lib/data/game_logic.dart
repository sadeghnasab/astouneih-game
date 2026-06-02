import 'dart:math';
import '../models/word_model.dart';

class GameLogic {
  // ==========================================
  // بخش اول: توابع مربوط به بازی ۴ گزینه‌ای
  // ==========================================

  static List<TatiWord> getWordsByLevel(
    List<TatiWord> allWords,
    int currentLevel,
  ) {
    List<TatiWord> filteredWords = allWords
        .where((word) => word.level <= currentLevel)
        .toList();
    return filteredWords.isNotEmpty ? filteredWords : allWords;
  }

  static List<TatiWord> generateQuestionOptions(
    List<TatiWord> availableWords,
    TatiWord correctWord,
  ) {
    List<TatiWord> options = [];
    options.add(correctWord);

    Random random = Random();
    while (options.length < 4) {
      int randomIndex = random.nextInt(availableWords.length);
      TatiWord randomWord = availableWords[randomIndex];

      if (!options.contains(randomWord)) {
        options.add(randomWord);
      }
    }
    options.shuffle();
    return options;
  }

  // ==========================================
  // بخش دوم: توابع جدید برای بازی معمای کلمات (پازل)
  // ==========================================

  // لیست حروف الفبا برای تولید حروف گمراه‌کننده (حروف تاتی و فارسی)
  static const String _persianAlphabet = "ابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهیآ";

  // این تابع کلمه را می‌گیرد و لیستی از حروف به‌هم‌ریخته برمی‌گرداند
  static List<String> generatePuzzleLetters(String correctTatiWord) {
    // ۱. حذف فاصله‌های احتمالی کلمه (مثلاً اگر دو کلمه‌ای بود به هم بچسبد)
    String wordWithoutSpaces = correctTatiWord.replaceAll(' ', '');

    // ۲. جدا کردن حروف کلمه اصلی
    List<String> letters = wordWithoutSpaces.split('');

    Random random = Random();

    // ۳. تعیین تعداد کل حروفی که می‌خواهیم روی صفحه نشان دهیم
    // حداقل ۱۰ دکمه روی صفحه می‌گذاریم، اگر کلمه طولانی بود، تعداد دکمه‌ها را بیشتر می‌کنیم
    int totalLettersTarget = wordWithoutSpaces.length + 4;
    if (totalLettersTarget < 10) totalLettersTarget = 10;

    // ۴. اضافه کردن حروف تصادفی و الکی تا رسیدن به تعداد مورد نظر
    while (letters.length < totalLettersTarget) {
      int randomIndex = random.nextInt(_persianAlphabet.length);
      String randomChar = _persianAlphabet[randomIndex];
      letters.add(randomChar);
    }

    // ۵. بُر زدن نهایی حروف تا جواب لو نرود
    letters.shuffle();

    return letters;
  }
}
