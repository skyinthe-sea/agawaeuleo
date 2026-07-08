/// 개인기록 엔티티 ↔ `pending_ops.payload`(JSON 문자열) 직렬화 (§5.3 동기화 큐).
///
/// 엔티티는 `json_serializable`을 쓰지 않으므로(§5.2 소스 교체 무영향 원칙) 동기화 큐에
/// 넣을 페이로드를 여기서 수동 직렬화한다. 리포지토리(enqueue)와 `SyncService`(flush 시
/// 복원)가 짝을 이뤄 사용한다. 날짜는 ISO8601(UTC 아님, 로컬 tz 정보 포함), enum은 `wire`.
///
/// delete 연산은 페이로드가 필요 없다(대상은 `pending_ops.localId`) — 빈 문자열을 쓴다.
library;

import 'dart:convert';

import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:agawaeuleo/domain/entities/favorite.dart';
import 'package:agawaeuleo/domain/entities/tracking_log.dart';

/// TrackingLog → JSON 문자열.
String encodeTrackingLog(TrackingLog log) => jsonEncode(<String, dynamic>{
  'id': log.id,
  'userId': log.userId,
  'babyId': log.babyId,
  'type': log.type.wire,
  'subtype': log.subtype?.wire,
  'amount': log.amount,
  'note': log.note,
  'startedAt': log.startedAt.toIso8601String(),
  'endedAt': log.endedAt?.toIso8601String(),
  'createdAt': log.createdAt.toIso8601String(),
});

/// JSON 문자열 → TrackingLog.
TrackingLog decodeTrackingLog(String payload) {
  final m = jsonDecode(payload) as Map<String, dynamic>;
  return TrackingLog(
    id: m['id'] as String,
    userId: m['userId'] as String,
    babyId: m['babyId'] as String?,
    type: TrackingType.fromWire(m['type'] as String),
    subtype: TrackingSubtype.tryFromWire(m['subtype'] as String?),
    amount: (m['amount'] as num?)?.toDouble(),
    note: m['note'] as String?,
    startedAt: DateTime.parse(m['startedAt'] as String),
    endedAt: m['endedAt'] == null
        ? null
        : DateTime.parse(m['endedAt'] as String),
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}

/// Baby → JSON 문자열.
String encodeBaby(Baby baby) => jsonEncode(<String, dynamic>{
  'id': baby.id,
  'userId': baby.userId,
  'name': baby.name,
  'birthDate': baby.birthDate?.toIso8601String(),
  'gender': baby.gender.wire,
  'createdAt': baby.createdAt.toIso8601String(),
});

/// JSON 문자열 → Baby.
Baby decodeBaby(String payload) {
  final m = jsonDecode(payload) as Map<String, dynamic>;
  return Baby(
    id: m['id'] as String,
    userId: m['userId'] as String,
    name: m['name'] as String,
    birthDate: m['birthDate'] == null
        ? null
        : DateTime.parse(m['birthDate'] as String),
    gender: BabyGender.fromWire(m['gender'] as String?),
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}

/// Favorite → JSON 문자열.
String encodeFavorite(Favorite favorite) => jsonEncode(<String, dynamic>{
  'id': favorite.id,
  'userId': favorite.userId,
  'targetType': favorite.targetType.wire,
  'targetId': favorite.targetId,
  'createdAt': favorite.createdAt.toIso8601String(),
});

/// JSON 문자열 → Favorite.
Favorite decodeFavorite(String payload) {
  final m = jsonDecode(payload) as Map<String, dynamic>;
  return Favorite(
    id: m['id'] as String,
    userId: m['userId'] as String,
    targetType: FavoriteTargetType.fromWire(m['targetType'] as String),
    targetId: m['targetId'] as String,
    createdAt: DateTime.parse(m['createdAt'] as String),
  );
}
