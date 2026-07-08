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
/// - 최소 표시 600ms를 보장(깜빡임 방지)하면서, 병렬로:
///   - `onboarding.done`(shared_preferences) 플래그로 첫 실행 여부를 판정.
///   - [AuthRepository.ensureSignedIn]으로 게스트(익명) 세션을 자동 생성(§4.1) — 인증을
///     강제하지 않는다(§2-8). 오프라인 등으로 실패해도 로컬 폴백이 있어 부팅을 막지 않는다.
///
/// TODO(M5): 원격 config 게이트(강제 업데이트/점검) — `appConfigRepositoryProvider`로
/// `RemoteAppConfig`를 조회해 `isForceUpdateRequired`/`maintenance`를 이 시점에 분기
/// 처리한다(§3.3, §7.1 `app_config`). 현재는 게이트 없이 항상 통과.
final splashBootProvider = FutureProvider.autoDispose<SplashDestination>((
  ref,
) async {
  const minDisplay = Duration(milliseconds: 600);
  final auth = ref.watch(authRepositoryProvider);

  Future<SplashDestination> boot() async {
    final done = await OnboardingPrefs.isDone();
    try {
      await auth.ensureSignedIn();
    } catch (_) {
      // 오프라인 등으로 실패해도 게스트 진입 자체는 막지 않는다(§2-8 가입 강요 금지).
    }
    return done ? SplashDestination.home : SplashDestination.onboarding;
  }

  final bootFuture = boot();
  await Future<void>.delayed(minDisplay);
  return await bootFuture;
});
