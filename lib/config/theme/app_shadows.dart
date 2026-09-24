import 'package:flutter/material.dart';

/// §9.5 음영(DESIGN v3 §3.2 개정 — "몽글 클레이": 넓고 부드럽게 퍼지는 장밋빛 그림자로
/// 표면이 폭신하게 떠 보이게). 회색 금지 — Light는 따뜻한 로즈브라운 rgba(150,96,84,α).
/// Dark는 근검정 드롭 + 상단 1px 하이라이트.
///
/// [press](오목) 인셋과 다크 상단 하이라이트는 `BlurStyle.inner` 로는 불투명 fill
/// 뒤에 그려져 가려진다(무효과). 따라서 [press] 는 소비처(app_card)에서
/// `foregroundDecoration` 으로 자식 위에 덧그려 렌더하고, 다크 상단 하이라이트는
/// [topHighlight] 색으로 노출해 소비처가 상단 1px 보더로 렌더한다.
@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.e1,
    required this.e2,
    required this.e3,
    required this.e4,
    required this.press,
    this.topHighlight,
  });

  final List<BoxShadow> e1;
  final List<BoxShadow> e2;
  final List<BoxShadow> e3;
  final List<BoxShadow> e4;

  /// §9.5 press 오목. `BlurStyle.inner` 인셋 — 소비처에서 `foregroundDecoration`
  /// 으로 자식 위에 덧그려야 실제로 보인다(fill 뒤 boxShadow로는 가려짐).
  final List<BoxShadow> press;

  /// §9.5 다크 카드 상단 1px 하이라이트(카드를 띄우는 먹빛 위 얇은 빛). Light는 없음(null).
  /// 소비처(app_card)가 상단 보더로 렌더한다.
  final Color? topHighlight;

  /// e0 = 음영 없음(양 모드 공통).
  static const List<BoxShadow> e0 = <BoxShadow>[];

  static const AppShadows light = AppShadows(
    e1: [
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.07),
        offset: Offset(0, 1),
        blurRadius: 3,
      ),
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.07),
        offset: Offset(0, 4),
        blurRadius: 12,
      ),
    ],
    e2: [
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.10),
        offset: Offset(0, 6),
        blurRadius: 18,
      ),
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.06),
        offset: Offset(0, 1),
        blurRadius: 4,
      ),
    ],
    e3: [
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.15),
        offset: Offset(0, 16),
        blurRadius: 36,
      ),
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.07),
        offset: Offset(0, 3),
        blurRadius: 8,
      ),
    ],
    e4: [
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.16),
        offset: Offset(0, 10),
        blurRadius: 26,
      ),
    ],
    press: [
      BoxShadow(
        color: Color.fromRGBO(150, 96, 84, 0.10),
        offset: Offset(0, 2),
        blurRadius: 5,
        blurStyle: BlurStyle.inner,
      ),
    ],
  );

  static const AppShadows dark = AppShadows(
    // 상단 하이라이트는 [topHighlight] 보더로 렌더한다(인셋 그림자는 fill에 가려 무효과).
    topHighlight: Color.fromRGBO(255, 255, 255, 0.06),
    e1: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.45),
        offset: Offset(0, 1),
        blurRadius: 3,
      ),
    ],
    e2: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.55),
        offset: Offset(0, 2),
        blurRadius: 10,
      ),
    ],
    e3: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.65),
        offset: Offset(0, 12),
        blurRadius: 32,
      ),
    ],
    e4: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.60),
        offset: Offset(0, 8),
        blurRadius: 22,
      ),
    ],
    press: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.5),
        offset: Offset(0, 1),
        blurRadius: 3,
        blurStyle: BlurStyle.inner,
      ),
    ],
  );

  @override
  AppShadows copyWith({
    List<BoxShadow>? e1,
    List<BoxShadow>? e2,
    List<BoxShadow>? e3,
    List<BoxShadow>? e4,
    List<BoxShadow>? press,
    Color? topHighlight,
  }) {
    return AppShadows(
      e1: e1 ?? this.e1,
      e2: e2 ?? this.e2,
      e3: e3 ?? this.e3,
      e4: e4 ?? this.e4,
      press: press ?? this.press,
      topHighlight: topHighlight ?? this.topHighlight,
    );
  }

  @override
  AppShadows lerp(covariant ThemeExtension<AppShadows>? other, double t) {
    if (other is! AppShadows) return this;
    return AppShadows(
      e1: BoxShadow.lerpList(e1, other.e1, t)!,
      e2: BoxShadow.lerpList(e2, other.e2, t)!,
      e3: BoxShadow.lerpList(e3, other.e3, t)!,
      e4: BoxShadow.lerpList(e4, other.e4, t)!,
      press: BoxShadow.lerpList(press, other.press, t)!,
      topHighlight: Color.lerp(topHighlight, other.topHighlight, t),
    );
  }
}
