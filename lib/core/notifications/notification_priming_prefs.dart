import 'package:shared_preferences/shared_preferences.dart';

/// §11.6 권한 프라이밍 노출 조건 헬퍼(노출 시점 개정판).
///
/// 프라이밍은 첫 실행 온보딩에 끼워넣지 않고 **첫 기록 저장 직후 1회**만 노출한다(수락률↑).
/// 이 클래스는 "아직 프라이밍을 보여준 적 없는가?"만 관리한다 — 실제 트리거(첫 기록 저장
/// 시점에서 [shouldShowAfterFirstRecord]를 확인하고 프라이밍 라우트로 이동)는 트래킹
/// 화면과의 통합 단계에서 배선한다.
class NotificationPrimingPrefs {
  const NotificationPrimingPrefs._();

  /// shared_preferences 저장 키.
  static const String prefsKey = 'notifications.priming.shown';

  /// 프라이밍을 한 번이라도 노출했는지.
  static Future<bool> hasShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  /// 첫 기록 저장 직후, 프라이밍을 노출해야 하는지(§11.6 "1회").
  /// 통합 단계에서 트래킹 저장 성공 콜백이 이 값을 확인해 라우트를 띄운다.
  static Future<bool> shouldShowAfterFirstRecord() async => !await hasShown();

  /// 프라이밍 노출(수락/스킵 무관)을 기록해 다시 뜨지 않게 한다.
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }
}
