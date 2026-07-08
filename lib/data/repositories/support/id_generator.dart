import 'dart:math';

/// 로컬 우선 저장(§5.3)에서 개인기록의 클라이언트 생성 식별자를 만든다.
///
/// 별도 패키지(`uuid`) 의존 없이 RFC 4122 v4(랜덤) uuid를 생성한다. 로컬에서 PK로
/// 쓰이고, 동기화 push 시 이 값을 서버 행 `id`로 그대로 전송하므로(서버 id == 로컬 id)
/// 서버·로컬 식별자가 일치한다.
final Random _random = Random.secure();

/// 새 RFC 4122 v4 uuid 문자열(소문자, 하이픈 포함)을 반환한다.
String newUuidV4() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  // version 4 (0100xxxx) + variant (10xxxxxx).
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
