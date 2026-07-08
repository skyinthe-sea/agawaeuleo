import 'dart:async';

import 'package:agawaeuleo/core/error/app_exception.dart';

/// 지수 백오프 재시도 헬퍼 (§5.3 갱신 전략 · §6.3 rate-limit 대비의 재시도 원칙을
/// 앱 읽기 경로에 적용).
///
/// [action]을 최대 [maxAttempts]회 시도한다. 실패마다 대기 시간을 2배로 늘리되
/// [maxDelay]로 상한을 둔다. 마지막 시도까지 실패하면 마지막 오류를 [AppException]으로
/// 변환해 던진다([AppException.from]가 이미 [AppException]이면 그대로 통과시킨다).
///
/// [retryIf]가 주어지면 해당 오류에 대해서만 재시도한다(예: 네트워크 오류만).
Future<T> retryWithBackoff<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 300),
  Duration maxDelay = const Duration(seconds: 5),
  bool Function(Object error)? retryIf,
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await action();
    } on Object catch (error, stackTrace) {
      final canRetry =
          attempt < maxAttempts && (retryIf == null || retryIf(error));
      if (!canRetry) {
        throw AppException.from(error, stackTrace);
      }
      final shift = attempt - 1;
      final grown = baseDelay.inMilliseconds * (1 << shift);
      final delayMs = grown > maxDelay.inMilliseconds
          ? maxDelay.inMilliseconds
          : grown;
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }
}
