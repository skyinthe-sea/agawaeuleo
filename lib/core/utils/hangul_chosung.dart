/// §11.8 한글 초성 추출·매칭.
/// 완성형 음절의 초성 index = (code − 0xAC00) ~/ 588. 초성열("ㅂㅇㅇ") 매칭,
/// 부분일치("배앓"), 동의어 배열 매칭, 공백·대소문자 무시를 제공한다.
class HangulChosung {
  const HangulChosung._();

  static const int _syllableBase = 0xAC00;
  static const int _syllableEnd = 0xD7A3;
  static const int _jongCount = 28;
  static const int _jungJongCount = 21 * _jongCount; // 588

  /// 완성형 초성 → 호환 자모(U+31xx). index 0..18.
  static const List<String> chosungTable = <String>[
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];

  static final Set<String> _chosungSet = chosungTable.toSet();

  /// 문자열의 완성형 음절을 초성으로 치환. 비음절(자모·영문·기호·공백)은 그대로 유지.
  static String extract(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= _syllableBase && rune <= _syllableEnd) {
        final index = (rune - _syllableBase) ~/ _jungJongCount;
        buffer.write(chosungTable[index]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// 단일 문자가 초성 자모인지.
  static bool isChosung(String char) => _chosungSet.contains(char);

  /// 질의가 (공백 제외) 초성 자모만으로 이루어졌는지 — 초성열 매칭 대상 판별.
  static bool isChosungQuery(String query) {
    var seen = false;
    for (final rune in query.runes) {
      final ch = String.fromCharCode(rune);
      if (_isWhitespace(rune)) continue;
      if (!_chosungSet.contains(ch)) return false;
      seen = true;
    }
    return seen;
  }

  /// [query]가 [target] 또는 [aliases] 중 하나에 매칭되면 true.
  /// 규칙: 공백 제거·소문자화 후 (1) 부분 문자열 일치, 그리고 질의가 초성열이면
  /// (2) 후보의 초성 문자열에 대한 연속 부분일치.
  static bool matches(
    String query,
    String target, {
    List<String> aliases = const <String>[],
  }) {
    final q = _normalize(query);
    if (q.isEmpty) return false;

    final chosungQuery = isChosungQuery(q);
    for (final candidate in <String>[target, ...aliases]) {
      final nc = _normalize(candidate);
      if (nc.isEmpty) continue;
      if (nc.contains(q)) return true;
      if (chosungQuery && extract(nc).contains(q)) return true;
    }
    return false;
  }

  /// 공백 제거 + 소문자화.
  static String _normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D;
}
