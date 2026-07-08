import 'package:flutter/services.dart';

/// §10.1 햅틱 시맨틱 래퍼. 호출부는 의미(탭/토글/완료)로만 접근한다.
class AppHaptics {
  const AppHaptics._();

  /// 주요 탭(카드·버튼·에러 등) — lightImpact.
  static Future<void> tap() => HapticFeedback.lightImpact();

  /// 토글·선택(스위치·칩·눈 아이콘·탭바) — selectionClick.
  static Future<void> toggle() => HapticFeedback.selectionClick();

  /// 완료(기록 저장 등) — mediumImpact.
  static Future<void> complete() => HapticFeedback.mediumImpact();
}
