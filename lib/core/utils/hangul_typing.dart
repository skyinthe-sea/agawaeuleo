/// 한글 두벌식 IME가 화면에 보여 주는 **조합 중간 상태**를 순서대로 만든다.
///
/// 타이핑 연출용(온보딩 검색 알약·홈 검색 힌트). 실제 키 입력 순서를 흉내 내어
/// 받침이 다음 음절 초성으로 넘어가는 순간까지 재현한다.
///
/// ```dart
/// hangulTypingSteps('배앓이');
/// // ['ㅂ', '배', '뱅', '배아', '배알', '배앓', '배앓ㅇ', '배앓이']
/// ```
///
/// - 겹모음(ㅘ 등)·겹받침(ㅀ 등)은 두 타로 나눈다.
/// - 한글 음절이 아닌 글자(공백·가운뎃점·영문)는 한 타로 그대로 붙인다.
List<String> hangulTypingSteps(String text) {
  final steps = <String>[];
  var committed = '';
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    final syllable = _Syllable.tryParse(rune);
    if (syllable == null) {
      committed += ch;
      steps.add(committed);
      continue;
    }

    // ① 초성 — 앞 음절에 받침이 비어 있으면 IME는 먼저 받침으로 붙였다가,
    // 모음이 들어오는 순간 다음 음절로 넘긴다(배 + ㅇ → 뱅 → 배아).
    final cho = _choJamo[syllable.cho];
    steps.add(_withInitial(committed, cho));

    // ② 중성(겹모음은 앞 모음부터).
    final firstVowel = _compoundVowels[syllable.jung];
    if (firstVowel != null) {
      steps.add(committed + _Syllable(syllable.cho, firstVowel, 0).char);
    }
    steps.add(committed + _Syllable(syllable.cho, syllable.jung, 0).char);

    // ③ 종성(겹받침은 앞 자음부터).
    if (syllable.jong != 0) {
      final compound = _compoundFinals[_jongJamo[syllable.jong]];
      if (compound != null) {
        final first = _jongJamo.indexOf(compound.$1);
        steps.add(
          committed + _Syllable(syllable.cho, syllable.jung, first).char,
        );
      }
      steps.add(committed + ch);
    }
    committed += ch;
  }
  return steps;
}

/// [text]를 끝에서부터 한 글자씩 지워 가는 상태(마지막은 빈 문자열).
List<String> hangulErasingSteps(String text) {
  final runes = text.runes.toList();
  return <String>[
    for (var i = runes.length - 1; i >= 0; i--)
      String.fromCharCodes(runes.sublist(0, i)),
  ];
}

/// [committed] 뒤에 초성 [cho]를 친 직후의 화면 상태.
String _withInitial(String committed, String cho) {
  if (committed.isEmpty) return cho;
  final lastRune = committed.runes.last;
  final prev = _Syllable.tryParse(lastRune);
  if (prev == null) return committed + cho;
  final head = String.fromCharCodes(committed.runes.toList()..removeLast());

  if (prev.jong == 0) {
    final jong = _jongJamo.indexOf(cho);
    if (jong > 0) return head + _Syllable(prev.cho, prev.jung, jong).char;
    return committed + cho;
  }
  // 홑받침 + 이 자음이 겹받침이 되면 IME는 겹받침으로 합친다(갈 + ㄱ → 갉).
  final current = _jongJamo[prev.jong];
  for (final entry in _compoundFinals.entries) {
    if (entry.value.$1 == current && entry.value.$2 == cho) {
      final jong = _jongJamo.indexOf(entry.key);
      return head + _Syllable(prev.cho, prev.jung, jong).char;
    }
  }
  return committed + cho;
}

class _Syllable {
  const _Syllable(this.cho, this.jung, this.jong);

  static const int _base = 0xAC00;
  static const int _last = 0xD7A3;

  final int cho;
  final int jung;
  final int jong;

  static _Syllable? tryParse(int rune) {
    if (rune < _base || rune > _last) return null;
    final offset = rune - _base;
    return _Syllable(offset ~/ 588, (offset % 588) ~/ 28, offset % 28);
  }

  String get char => String.fromCharCode(_base + (cho * 21 + jung) * 28 + jong);
}

/// 초성 19자(호환 자모).
const List<String> _choJamo = <String>[
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', //
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

/// 종성 28자(0 = 받침 없음, 호환 자모).
const List<String> _jongJamo = <String>[
  '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', //
  'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', //
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

/// 겹모음 중성 인덱스 → 먼저 치는 모음의 중성 인덱스
/// (ㅘ·ㅙ·ㅚ ← ㅗ, ㅝ·ㅞ·ㅟ ← ㅜ, ㅢ ← ㅡ).
const Map<int, int> _compoundVowels = <int, int>{
  9: 8,
  10: 8,
  11: 8,
  14: 13,
  15: 13,
  16: 13,
  19: 18,
};

/// 겹받침 → (앞 자음, 뒤 자음).
const Map<String, (String, String)> _compoundFinals =
    <String, (String, String)>{
      'ㄳ': ('ㄱ', 'ㅅ'),
      'ㄵ': ('ㄴ', 'ㅈ'),
      'ㄶ': ('ㄴ', 'ㅎ'),
      'ㄺ': ('ㄹ', 'ㄱ'),
      'ㄻ': ('ㄹ', 'ㅁ'),
      'ㄼ': ('ㄹ', 'ㅂ'),
      'ㄽ': ('ㄹ', 'ㅅ'),
      'ㄾ': ('ㄹ', 'ㅌ'),
      'ㄿ': ('ㄹ', 'ㅍ'),
      'ㅀ': ('ㄹ', 'ㅎ'),
      'ㅄ': ('ㅂ', 'ㅅ'),
    };
