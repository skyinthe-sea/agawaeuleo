import 'package:agawaeuleo/core/utils/hangul_chosung.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extract', () {
    test('완성형 음절을 초성으로 치환', () {
      expect(HangulChosung.extract('배앓이'), 'ㅂㅇㅇ');
      expect(HangulChosung.extract('열'), 'ㅇ');
      expect(HangulChosung.extract('감기'), 'ㄱㄱ');
      expect(HangulChosung.extract('딸꾹질'), 'ㄸㄲㅈ');
    });

    test('자음만/모음만 등 비음절은 그대로 유지', () {
      expect(HangulChosung.extract('ㅂㅇㅇ'), 'ㅂㅇㅇ');
      expect(HangulChosung.extract('ㅏㅑ'), 'ㅏㅑ');
    });

    test('혼합(한글+영문+공백+기호) 처리', () {
      expect(HangulChosung.extract('배a 이'), 'ㅂa ㅇ');
      expect(HangulChosung.extract('열(fever)'), 'ㅇ(fever)');
    });

    test('빈 문자열/영문', () {
      expect(HangulChosung.extract(''), '');
      expect(HangulChosung.extract('abc'), 'abc');
      expect(HangulChosung.extract('Gas Relief'), 'Gas Relief');
    });

    test('음절 경계값(가/힣)', () {
      expect(HangulChosung.extract('가'), 'ㄱ');
      expect(HangulChosung.extract('힣'), 'ㅎ');
    });
  });

  group('isChosung / isChosungQuery', () {
    test('단일 초성 판별', () {
      expect(HangulChosung.isChosung('ㅂ'), isTrue);
      expect(HangulChosung.isChosung('ㄲ'), isTrue);
      expect(HangulChosung.isChosung('ㅏ'), isFalse);
      expect(HangulChosung.isChosung('배'), isFalse);
      expect(HangulChosung.isChosung('a'), isFalse);
    });

    test('초성열 질의 판별(공백 무시)', () {
      expect(HangulChosung.isChosungQuery('ㅂㅇㅇ'), isTrue);
      expect(HangulChosung.isChosungQuery('ㅂ ㅇㅇ'), isTrue);
      expect(HangulChosung.isChosungQuery('배'), isFalse);
      expect(HangulChosung.isChosungQuery('ㅂ애'), isFalse);
      expect(HangulChosung.isChosungQuery('ㅏ'), isFalse);
      expect(HangulChosung.isChosungQuery(''), isFalse);
      expect(HangulChosung.isChosungQuery('   '), isFalse);
    });
  });

  group('matches — 초성열', () {
    test('완전 초성열 일치', () {
      expect(HangulChosung.matches('ㅂㅇㅇ', '배앓이'), isTrue);
    });

    test('부분 초성열(연속) 일치', () {
      expect(HangulChosung.matches('ㅂㅇ', '배앓이'), isTrue);
      expect(HangulChosung.matches('ㅇㅇ', '배앓이'), isTrue);
    });

    test('순서 불일치는 실패', () {
      expect(HangulChosung.matches('ㅇㅂ', '배앓이'), isFalse);
    });

    test('없는 초성은 실패', () {
      expect(HangulChosung.matches('ㅋ', '배앓이'), isFalse);
    });
  });

  group('matches — 부분일치', () {
    test('완성형 부분 문자열', () {
      expect(HangulChosung.matches('배앓', '배앓이'), isTrue);
      expect(HangulChosung.matches('앓이', '배앓이'), isTrue);
      expect(HangulChosung.matches('배앓이', '배앓이'), isTrue);
    });

    test('포함되지 않으면 실패', () {
      expect(HangulChosung.matches('설사', '배앓이'), isFalse);
    });
  });

  group('matches — 동의어/정규화', () {
    test('동의어 배열 부분일치', () {
      expect(
        HangulChosung.matches('가스', '배앓이', aliases: ['가스', '영아산통']),
        isTrue,
      );
    });

    test('초성열 질의는 동의어를 보지 않고 이름에만 매칭한다', () {
      // 동의어(alias)는 부분일치에만 참여한다 — 초성열 질의가 동의어까지 보면
      // 여러 단어가 이어붙을 때 단어 경계와 무관한 우연한 일치가 섞인다.
      expect(HangulChosung.matches('ㄱㅅ', '배앓이', aliases: ['가스']), isFalse);
    });

    test('동의어 문구 중간의 우연한 초성 조합은 매칭되지 않는다', () {
      // "얼굴 붉어짐"의 초성열은 (공백 제거 후) 'ㅇㄱㅂㅇㅈ' — 중간의 '붉어'가
      // 우연히 'ㅂㅇ'와 일치하지만, 대상 이름("태열")의 초성 'ㅌㅇ'과는
      // 무관하므로 매칭되면 안 된다.
      expect(HangulChosung.matches('ㅂㅇ', '태열', aliases: ['얼굴 붉어짐']), isFalse);
    });

    test('공백 무시', () {
      expect(HangulChosung.matches('  배 앓  ', '배 앓 이'), isTrue);
      expect(HangulChosung.matches('ㅂ ㅇ ㅇ', '배앓이'), isTrue);
    });

    test('대소문자 무시(영문)', () {
      expect(
        HangulChosung.matches('GAS', '설사', aliases: ['Gas Relief']),
        isTrue,
      );
      expect(HangulChosung.matches('fever', '열', aliases: ['Fever']), isTrue);
    });
  });

  group('matches — 엣지케이스', () {
    test('빈 질의는 매칭 안 함', () {
      expect(HangulChosung.matches('', '배앓이'), isFalse);
      expect(HangulChosung.matches('   ', '배앓이'), isFalse);
    });

    test('빈 대상은 매칭 안 함', () {
      expect(HangulChosung.matches('배', ''), isFalse);
      expect(HangulChosung.matches('배', '', aliases: ['']), isFalse);
    });

    test('영문 대상 + 한글 질의', () {
      expect(HangulChosung.matches('ㅂ', 'baby'), isFalse);
    });
  });
}
