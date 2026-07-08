import 'package:shared_preferences/shared_preferences.dart';

/// §11.1·§11.2 첫 실행 판정 플래그.
///
/// `onboarding.done`이 true면 스플래시가 곧장 홈(게스트)으로 보내고, 아니면 온보딩
/// 3장을 노출한다(§4.1). "시작하기"와 "건너뛰기" 모두 이 플래그를 true로 남긴다.
class OnboardingPrefs {
  const OnboardingPrefs._();

  /// shared_preferences 저장 키.
  static const String prefsKey = 'onboarding.done';

  /// 온보딩을 마쳤는지(또는 건너뛰었는지) 여부. 기본값 false(첫 실행).
  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  /// 온보딩 완료(또는 스킵)를 기록한다(§11.2 "시작하기"/"건너뛰기" 공통 동작).
  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }
}
