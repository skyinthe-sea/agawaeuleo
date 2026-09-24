import 'package:flutter/widgets.dart';

import '../../../widgets/symptom/symptom_illustration.dart';

/// 브랜드 로고(작게) — DESIGN v3 "몽글 클레이": 스플래시 배지와 같은 **방긋 웃는 클레이
/// 아가 얼굴**([ClayScenes.babySmile]).
///
/// 이름은 v2(수묵 물방울 로고) 시절의 역사적 이름이다 — 소비처(로그인 화면 `AuthLogo`)를
/// 흔들지 않도록 공개 API(`size`)를 그대로 유지한다. 뒤의 톤 쿠션(헤일로/버블)은
/// 소비처가 깐다. 장식이므로 시맨틱스에서 제외된다(에셋이 없으면 빈 자리).
class InkDropLogo extends StatelessWidget {
  const InkDropLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClayIllustration(asset: ClayScenes.babySmile, size: size);
  }
}
