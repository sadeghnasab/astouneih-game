class TatiWord {
  final int id;
  final String faWord;
  final String tatiWord;
  final String pronunciation;
  final int level;

  TatiWord({
    required this.id,
    required this.faWord,
    required this.tatiWord,
    required this.pronunciation,
    this.level = 1,
  });

  factory TatiWord.fromJson(Map<String, dynamic> json) {
    return TatiWord(
      id: int.parse(json['ID'].toString()),
      faWord: json['fa_word'].toString(),
      tatiWord: json['tati_word'].toString(),
      pronunciation: json['pronunciation'].toString(),
      // اینجا 'Level' رو با L بزرگ نوشتیم تا دقیقاً با فایل جیسون شما یکی بشه
      level: json['Level'] != null ? int.parse(json['Level'].toString()) : 1,
    );
  }
}
