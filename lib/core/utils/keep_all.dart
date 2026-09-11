import 'package:flutter/widgets.dart' show StringCharacters;

/// 폭 없는 WORD JOINER(U+2060) — 이 문자 양옆에서는 줄이 바뀌지 않는다.
const String _wordJoiner = '\u2060';

/// 한국어 어절 단위 줄바꿈 — CSS `word-break: keep-all` 흉내.
///
/// Flutter 텍스트 엔진은 한글을 음절마다 끊을 수 있어 "바로 보\n기"처럼 한 글자가
/// 다음 줄로 떨어진다. 어절 안의 글자 사이에 [_wordJoiner]를 넣어 공백에서만 줄이
/// 바뀌게 한다. 표시 전용 — 검색·비교용 원문에는 쓰지 말 것.
String keepAll(String text) =>
    text.split(' ').map((word) => word.characters.join(_wordJoiner)).join(' ');
