import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../data/onboarding_prefs.dart';

/// §11.1 스플래시 부팅 분기 목적지.
enum SplashDestination {
  /// 첫 실행(온보딩 미완료) — 온보딩으로 이동.
  onboarding,

  /// 온보딩 완료 — 곧장 홈(게스트, §4.1)으로 이동.
  home,
}

/// §11.1 스플래시 부팅 로직(수동 Riverpod — 코드젠 없음, autoDispose).
///
/// - 최소 표시 1150ms를 보장(브랜드 스테이지 연출이 끝나는 길이 — 2026-09-11 600ms에서
///   상향, `splash_screen.dart` `_introDuration`과 같은 값)하면서, 병렬로:
///   - `onboarding.done`(shared_preferences) 플래그로 첫 실행 여부를 판정.
///   - [AuthRepository.ensureSignedIn]으로 게스트(익명) 세션을 자동 생성(§4.1) — 인증을
///     강제하지 않는다(§2-8). 오프라인 등으로 실패해도 로컬 폴백이 있어 부팅을 막지 않는다.
///
/// 원격 config 게이트(강제 업데이트/점검, §3.3)는 이 부팅 분기와 병렬로 `appGateProvider`가
/// 담당하며, `SplashScreen`이 게이트 통과 시에만 여기서 산출한 목적지로 이동한다.
final splashBootProvider = FutureProvider.autoDispose<SplashDestination>((
  ref,
) async {
  const minDisplay = Duration(milliseconds: 1150);
  final auth = ref.watch(authRepositoryProvider);
  final cacheService = ref.watch(masterDataCacheServiceProvider);

  Future<SplashDestination> boot() async {
    final done = await OnboardingPrefs.isDone();
    try {
      await auth.ensureSignedIn();
    } catch (_) {
      // 오프라인 등으로 실패해도 게스트 진입 자체는 막지 않는다(§2-8 가입 강요 금지).
    }
    // 마스터 데이터 캐시 첫 동기화(§5.3): 콜드 캐시(첫 실행)에서만 대기해 빈 홈을
    // 막고, 이미 캐시가 있으면 즉시 진행(백그라운드 재검증). 미구성 시 즉시 반환.
    await cacheService.ensureFirstSync();
    return done ? SplashDestination.home : SplashDestination.onboarding;
  }

  final bootFuture = boot();
  await Future<void>.delayed(minDisplay);
  return await bootFuture;
});
