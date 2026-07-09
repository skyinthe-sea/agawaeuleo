import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// (프라이버시 존중) 애널리틱스 인터페이스 — §3.3 / §16.1 자리.
///
/// 이 파일은 **이벤트 훅만** 정의하는 자리표(placeholder)다. 지금은 실제 원격 전송을
/// 하지 않는다(전 문자열·화면 계측 이관은 범위 밖). 나중에 애널리틱스 SDK를 붙일 때
/// 이 인터페이스만 구현체로 갈아끼우면 되도록 호출부는 의미(이벤트/화면)만 알게 한다.
///
/// 프라이버시 원칙(§8·§13):
/// - **개인 식별정보(PII)를 절대 파라미터로 넣지 않는다** — 아기 이름·이메일·자유입력
///   메모·정확한 위치 등은 이벤트 속성에 담지 말 것. 저수준 카운트/enum 값만.
/// - 사용자 식별자(uid)를 이벤트에 첨부하지 않는다. 익명 집계만 전제.
/// - 기본 구현은 no-op(전송 없음)이며, 계측 도입 전까지 동작 회귀가 없다.
abstract interface class Analytics {
  /// 이름 있는 이벤트를 기록한다. [parameters] 는 PII 가 아닌 저카디널리티 값만.
  void logEvent(String name, {Map<String, Object?>? parameters});

  /// 화면 조회를 기록한다. [screenName] 은 라우트/화면 식별용 상수 문자열.
  void logScreenView(String screenName);
}

/// 아무것도 하지 않는 기본 구현. 애널리틱스 미구성 시의 안전한 폴백(동작 회귀 없음).
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  void logEvent(String name, {Map<String, Object?>? parameters}) {}

  @override
  void logScreenView(String screenName) {}
}

/// 디버그 로깅 구현. 원격 전송 없이 `dart:developer` 로그로만 이벤트를 흘려
/// 개발 중 계측 훅이 제대로 불리는지 확인한다. 릴리스 빌드에서는 no-op.
///
/// PII 를 남기지 않도록, 넘어온 [parameters] 도 그대로 신뢰하지 말고 호출부에서
/// 저카디널리티 값만 전달하는 규약을 지킨다(위 인터페이스 주석 참조).
class LoggerAnalytics implements Analytics {
  const LoggerAnalytics();

  static const String _name = 'analytics';

  @override
  void logEvent(String name, {Map<String, Object?>? parameters}) {
    if (!kDebugMode) return;
    final suffix = (parameters == null || parameters.isEmpty)
        ? ''
        : ' $parameters';
    developer.log('event: $name$suffix', name: _name);
  }

  @override
  void logScreenView(String screenName) {
    if (!kDebugMode) return;
    developer.log('screen: $screenName', name: _name);
  }
}
