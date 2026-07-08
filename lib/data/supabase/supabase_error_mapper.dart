import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';

/// 하위 소스(Supabase/gotrue/postgrest/네트워크) 예외를 앱 전역 [AppException]
/// 계열로 변환한다. data 레이어의 모든 원격 호출은 이 매퍼를 통과시켜, 화면·리포지토리가
/// `package:supabase_flutter`의 예외 타입에 직접 의존하지 않도록 한다.
///
/// - [AppException] : 그대로 반환(이중 래핑 방지).
/// - [AuthException]/[AuthApiException] : [AppAuthException] (재시도성 fetch 오류는 네트워크로).
/// - [PostgrestException] : 코드에 따라 not-found/네트워크/그 외.
/// - [TimeoutException] · SocketException 계열 · http `ClientException` : [AppNetworkException].
/// - 그 밖 : [AppUnknownException].
AppException mapSupabaseError(Object error, [StackTrace? stackTrace]) {
  if (error is AppException) return error;

  if (error is AuthRetryableFetchException) {
    return AppNetworkException(cause: error, stackTrace: stackTrace);
  }
  if (error is AuthException) {
    return AppAuthException(
      message: error.message,
      code: error.code ?? error.statusCode,
      cause: error,
      stackTrace: stackTrace,
    );
  }
  if (error is PostgrestException) {
    // PGRST116 = 결과 0행(single() 대상 없음) → not-found.
    if (error.code == 'PGRST116') {
      return AppNotFoundException(cause: error, stackTrace: stackTrace);
    }
    if (_looksLikeNetwork(error.message)) {
      return AppNetworkException(cause: error, stackTrace: stackTrace);
    }
    return AppUnknownException(
      message: error.message,
      code: error.code,
      cause: error,
      stackTrace: stackTrace,
    );
  }
  if (error is TimeoutException || _looksLikeNetwork(error.toString())) {
    return AppNetworkException(cause: error, stackTrace: stackTrace);
  }
  return AppUnknownException(cause: error, stackTrace: stackTrace);
}

/// dart:io 의존 없이(웹 호환) 문자열 휴리스틱으로 네트워크 오류를 감지.
bool _looksLikeNetwork(String text) {
  final t = text.toLowerCase();
  return t.contains('socketexception') ||
      t.contains('clientexception') ||
      t.contains('failed host lookup') ||
      t.contains('connection closed') ||
      t.contains('connection refused') ||
      t.contains('connection reset') ||
      t.contains('network is unreachable') ||
      t.contains('timed out') ||
      t.contains('timeout');
}

/// [Stream]의 error 이벤트를 [AppException] 으로 변환해 재방출하는 확장.
/// 원격 실시간 스트림은 `.mapErrorToAppException()` 을 마지막에 붙여 사용한다.
extension AppExceptionStream<T> on Stream<T> {
  Stream<T> mapErrorToAppException() => transform(
    StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        sink.addError(mapSupabaseError(error, stackTrace), stackTrace);
      },
    ),
  );
}
