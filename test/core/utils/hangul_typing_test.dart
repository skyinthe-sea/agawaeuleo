import 'package:agawaeuleo/core/utils/hangul_typing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('받침이 다음 음절 초성으로 넘어가는 순간까지 재현한다', () {
    expect(hangulTypingSteps('배앓이'), <String>[
      'ㅂ',
      '배',
      '뱅',
      '배아',
      '배알',
      '배앓',
      '배앓ㅇ',
      '배앓이',
    ]);
  });

  test('겹모음은 두 타, 홑받침 + 자음은 겹받침으로 먼저 합쳐진다', () {
    expect(hangulTypingSteps('과'), <String>['ㄱ', '고', '과']);
    expect(hangulTypingSteps('갈가'), <String>['ㄱ', '가', '갈', '갉', '갈가']);
  });

  test('한글이 아닌 글자는 한 타로 그대로 붙고, 마지막 상태는 원문이다', () {
    const text = '콧물·코막힘';
    final steps = hangulTypingSteps(text);
    expect(steps.last, text);
    expect(steps, contains('콧물·'));
    expect(hangulTypingSteps(''), isEmpty);
  });

  test('지우기는 끝에서부터 한 글자씩 비운다', () {
    expect(hangulErasingSteps('열·땀'), <String>['열·', '열', '']);
  });
}
