import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/utils/hangul_chosung.dart';
import 'package:flutter/widgets.dart';

/// §11.8 매칭 하이라이트 계산.
///
/// 표시명에서 하이라이트할 rune 인덱스 집합을 구한다. 규칙:
///  1) 부분(문자) 일치면 매칭된 부분 문자열의 음절,
///  2) 질의가 초성열이면 초성이 연속 일치하는 음절.
/// 공백·대소문자는 무시한다. 별칭으로만 매칭된 경우 표시명엔 하이라이트가 없다(빈 집합).
class SearchHighlight {
  const SearchHighlight._();

  /// [name]에서 [query]에 매칭되어 강조할 원본 rune 인덱스 집합.
  static Set<int> indices(String name, String query) {
    final nq = _normalize(query);
    if (nq.isEmpty) return const <int>{};

    final runes = name.runes.toList(growable: false);

    // 공백 제거 + 소문자화한 필터열 ↔ 원본 rune 인덱스 매핑.
    final origIndex = <int>[];
    final lower = <String>[];
    for (var i = 0; i < runes.length; i++) {
      if (_isWhitespace(runes[i])) continue;
      origIndex.add(i);
      lower.add(String.fromCharCode(runes[i]).toLowerCase());
    }

    final q = nq.runes.map(String.fromCharCode).toList(growable: false);

    // 1) 부분(문자) 일치.
    final direct = _findRun(lower, q);
    if (direct != null) {
      return <int>{for (var k = 0; k < q.length; k++) origIndex[direct + k]};
    }

    // 2) 초성열 일치 — 각 음절을 초성으로 치환한 열에서 연속 부분일치.
    if (HangulChosung.isChosungQuery(nq)) {
      final chosung = lower.map(HangulChosung.extract).toList(growable: false);
      final run = _findRun(chosung, q);
      if (run != null) {
        return <int>{for (var k = 0; k < q.length; k++) origIndex[run + k]};
      }
    }

    return const <int>{};
  }

  /// [haystack]에서 [needle]이 처음 연속 일치하는 시작 인덱스(없으면 null).
  static int? _findRun(List<String> haystack, List<String> needle) {
    if (needle.isEmpty || needle.length > haystack.length) return null;
    for (var start = 0; start + needle.length <= haystack.length; start++) {
      var ok = true;
      for (var k = 0; k < needle.length; k++) {
        if (haystack[start + k] != needle[k]) {
          ok = false;
          break;
        }
      }
      if (ok) return start;
    }
    return null;
  }

  static String _normalize(String s) =>
      s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D;
}

/// §11.8 매칭 글자 하이라이트 텍스트. 매칭 음절/부분은 `accent` 글자 + `accentWash`
/// 형광펜 면으로 강조한다.
///
/// DESIGN v3 §3.3 — 주아체(display)는 한 가지 굵기라 굵기를 올리면 가짜 볼드가 생긴다.
/// 그래서 기본 스타일이 주아체면 굵기는 그대로 두고 색·형광펜만으로 강조하고, 본문
/// 서체(Pretendard)일 때만 스펙대로 볼드를 더한다.
class HighlightedName extends StatelessWidget {
  const HighlightedName({
    required this.name,
    required this.query,
    required this.baseStyle,
    super.key,
    this.maxLines = 2,
  });

  final String name;
  final String query;
  final TextStyle baseStyle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final marks = SearchHighlight.indices(name, query);
    if (marks.isEmpty) {
      return Text(
        name,
        style: baseStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final colors = context.colors;
    final isDisplay = baseStyle.fontFamily == AppFontFamily.display;
    final highlightStyle = baseStyle.copyWith(
      color: colors.accent,
      backgroundColor: colors.accentWash,
      fontWeight: isDisplay ? baseStyle.fontWeight : FontWeight.w700,
    );

    final runes = name.runes.toList(growable: false);
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    bool? highlighted;

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(
        TextSpan(
          text: buffer.toString(),
          style: highlighted! ? highlightStyle : baseStyle,
        ),
      );
      buffer.clear();
    }

    for (var i = 0; i < runes.length; i++) {
      final isMark = marks.contains(i);
      if (highlighted != null && isMark != highlighted) flush();
      highlighted = isMark;
      buffer.writeCharCode(runes[i]);
    }
    flush();

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
