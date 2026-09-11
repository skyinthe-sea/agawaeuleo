import 'package:agawaeuleo/core/utils/keep_all.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('어절 안의 글자 사이에만 WORD JOINER를 넣고 공백은 그대로 둔다', () {
    expect(keepAll('바로 보기'), '바⁠로 보⁠기');
  });

  test('한 글자 어절과 문장부호도 깨지지 않는다', () {
    expect(keepAll('열, 이앓이'), '열⁠, 이⁠앓⁠이');
    expect(keepAll('').isEmpty, isTrue);
  });

  test('WORD JOINER를 지우면 원문과 같다', () {
    const text = '배앓이부터 발열까지, 궁금한 증상을 검색하세요.';
    expect(keepAll(text).replaceAll('⁠', ''), text);
  });
}
