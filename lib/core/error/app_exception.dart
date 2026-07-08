/// 앱 전역 예외 계층 (Result 타입 대신 예외 + 스트림 error 이벤트 기반).
///
/// data 레이어는 하위 소스 오류(Supabase `PostgrestException`/`AuthException`,
/// `SocketException` 등)를 잡아 이 계열로 변환해 던진다. 이름에 `App` 접두사를 두어
/// `package:supabase_flutter`의 `AuthException`과 충돌하지 않게 한다.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause, this.stackTrace});

  /// 사용자에게 보여줄 수 있는 한국어 메시지.
  final String message;

  /// 선택적 오류 코드(예: 인증 실패 사유).
  final String? code;

  /// 원인이 된 하위 예외(로깅/크래시 리포팅용).
  final Object? cause;

  /// 원인 예외의 스택트레이스.
  final StackTrace? stackTrace;

  /// 이미 [AppException]이면 그대로, 아니면 [AppUnknownException]으로 감싼다.
  static AppException from(Object error, [StackTrace? stackTrace]) =>
      error is AppException
      ? error
      : AppUnknownException(cause: error, stackTrace: stackTrace);

  @override
  String toString() {
    final prefix = code == null ? '' : '[$code] ';
    return '$runtimeType: $prefix$message';
  }
}

/// 네트워크 연결/타임아웃/오프라인 등 통신 실패.
final class AppNetworkException extends AppException {
  const AppNetworkException({
    String message = '네트워크에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.',
    super.code,
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// 인증/세션/권한 실패(로그인·계정 연결·RLS 등).
final class AppAuthException extends AppException {
  const AppAuthException({
    String message = '인증에 실패했어요. 다시 시도해 주세요.',
    super.code,
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// 요청한 리소스가 존재하지 않음.
final class AppNotFoundException extends AppException {
  const AppNotFoundException({
    String message = '요청한 데이터를 찾을 수 없어요.',
    super.code,
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// 분류되지 않은 그 밖의 오류.
final class AppUnknownException extends AppException {
  const AppUnknownException({
    String message = '알 수 없는 오류가 발생했어요.',
    super.code,
    super.cause,
    super.stackTrace,
  }) : super(message);
}
