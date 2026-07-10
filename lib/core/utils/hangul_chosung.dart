/// §11.8 한글 초성 추출·매칭.
/// 완성형 음절의 초성 index = (code − 0xAC00) ~/ 588. 초성열("ㅂㅇㅇ") 매칭은
/// 이름(target)에만 적용되고, 부분일치("배앓")는 이름·동의어(aliases) 모두에
/// 적용된다. 공백·대소문자는 무시한다.
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
  /// 규칙: 질의가 초성열이면 [target]의 초성 문자열에 대해서만 연속 부분일치를
  /// 검사한다 — 동의어(alias) 문구는 여러 단어가 이어붙는 경우가 많아, 이를
  /// 초성 매칭 대상에 포함하면 단어 경계와 무관하게 우연히 일치하는 초성
  /// 조합(예: "얼굴 붉어짐"의 중간 "붉어")으로 무관한 증상이 결과에 섞인다.
  /// 질의가 일반 텍스트면 공백 제거·소문자화 후 [target]과 [aliases] 모두에
  /// 대해 부분 문자열 일치를 검사한다.
  static bool matches(
    String query,
    String target, {
    List<String> aliases = const <String>[],
  }) {
    final q = _normalize(query);
    if (q.isEmpty) return false;

    final nt = _normalize(target);
    if (nt.isEmpty) return false;

    if (isChosungQuery(q)) {
      return extract(nt).contains(q);
    }

    if (nt.contains(q)) return true;
    for (final alias in aliases) {
      final na = _normalize(alias);
      if (na.isNotEmpty && na.contains(q)) return true;
    }
    return false;
  }

  /// 공백 제거 + 소문자화.
  static String _normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D;
}
