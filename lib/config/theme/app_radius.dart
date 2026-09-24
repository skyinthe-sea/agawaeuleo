import 'package:flutter/widgets.dart';

/// §9.4 모서리 반경(dp) — DESIGN v3 §3.4에서 한 단계씩 더 둥글게(말랑한 점토 표면).
/// 한 변 보더에는 radius 0, 전체 보더에만 사용.
class AppRadius {
  const AppRadius._();

  static const double xs = 8;
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 26;
  static const double xl = 34;
  static const double full = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brFull = BorderRadius.all(Radius.circular(full));
}
