import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracking_log.freezed.dart';

/// 기록 종류 (§7.1 `tracking_logs.type` = 'feed'|'sleep'|'diaper', §3 S1).
enum TrackingType {
  feed('feed'),
  sleep('sleep'),
  diaper('diaper');

  const TrackingType(this.wire);

  /// DB `type` 텍스트 값.
  final String wire;

  /// DB 텍스트 → enum. 알 수 없으면 예외.
  static TrackingType fromWire(String value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'Unknown TrackingType');
  }

  /// DB 텍스트 → enum. 알 수 없거나 null이면 null.
  static TrackingType? tryFromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// 기록 하위 종류 (§7.1 `tracking_logs.subtype`, §11.11).
///
/// - feed: [breast] / [formula] / [solid]
/// - diaper: [pee] / [poo] / [mixed]
/// - sleep: 하위 종류 없음(null).
enum TrackingSubtype {
  breast('breast'),
  formula('formula'),
  solid('solid'),
  pee('pee'),
  poo('poo'),
  mixed('mixed');

  const TrackingSubtype(this.wire);

  /// DB `subtype` 텍스트 값.
  final String wire;

  /// DB 텍스트 → enum. 알 수 없으면 예외.
  static TrackingSubtype fromWire(String value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'Unknown TrackingSubtype');
  }

  /// DB 텍스트 → enum. 알 수 없거나 null이면 null.
  static TrackingSubtype? tryFromWire(String? value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return null;
  }
}

/// 육아 기록 엔티티 (§7.1 `tracking_logs`, §3 S1, §11.10~11.11).
///
/// [endedAt]이 null이면 진행 중 타이머(수면/모유) 상태다(§11.11). 로컬 우선
/// 저장 후 Supabase 동기화(§5.3) — 매핑은 data 레이어가 담당.
@freezed
abstract class TrackingLog with _$TrackingLog {
  const TrackingLog._();

  const factory TrackingLog({
    required String id,
    required String userId,

    /// `baby_id`(nullable — 선택된 아기 없이도 기록 가능).
    String? babyId,

    /// `type`.
    required TrackingType type,

    /// `subtype`(nullable — sleep은 null).
    TrackingSubtype? subtype,

    /// `amount` — ml, 분 등(nullable).
    double? amount,

    /// `note`(nullable).
    String? note,

    /// `started_at`.
    required DateTime startedAt,

    /// `ended_at`(nullable). null = 진행 중 타이머(§11.11).
    DateTime? endedAt,

    required DateTime createdAt,
  }) = _TrackingLog;

  /// 종료 시각이 없으면 진행 중(타이머 동작) — §11.11.
  bool get isInProgress => endedAt == null;

  /// 종료된 기록의 소요 시간. 진행 중이면 null.
  Duration? get duration => endedAt?.difference(startedAt);

  /// [now] 기준 경과 시간(진행 중 배지 "· 1:23"용 — §11.11).
  Duration elapsedFrom(DateTime now) => (endedAt ?? now).difference(startedAt);
}
