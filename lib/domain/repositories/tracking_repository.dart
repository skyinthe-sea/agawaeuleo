import '../entities/tracking_log.dart';

/// 육아 기록 저장소 (§3 S1/S2, §7.1 `tracking_logs`, §11.10~11.11).
///
/// 쓰기는 로컬 우선 저장 후 Supabase 동기화(§5.3) — 오프라인에서도 기록 가능.
/// 실패 시 구현체는 `AppException` 계열을 던지거나 스트림 error 이벤트로 전달한다.
abstract class TrackingRepository {
  /// [day]의 로컬 캘린더 날짜에 속한 기록을 `started_at` 역순으로 관찰(§11.10 타임라인).
  /// [babyId]가 주어지면 해당 아기로 스코프(null이면 미지정 아기 기록 포함 전체).
  Stream<List<TrackingLog>> watchByDay({required DateTime day, String? babyId});

  /// [day]의 기록 1회 조회.
  Future<List<TrackingLog>> getByDay({required DateTime day, String? babyId});

  /// 기록 추가. 저장된(서버 id 확정) 로그를 반환.
  Future<TrackingLog> add(TrackingLog log);

  /// 기록 수정. 수정된 로그를 반환.
  Future<TrackingLog> update(TrackingLog log);

  /// 기록 삭제(§11.10 좌스와이프 삭제).
  Future<void> delete(String id);

  /// 진행 중(ended_at == null) 타이머 로그 관찰(§11.11 "진행 중" 배지).
  Stream<List<TrackingLog>> watchInProgress({String? babyId});

  /// 진행 중 타이머 로그 1회 조회(앱 재시작 복원 — §11.11).
  Future<List<TrackingLog>> getInProgress({String? babyId});

  /// 진행 중 로그를 종료 — [endedAt] 설정(§11.11). 모유 타이머 종료 시 [amount]/[note]도
  /// 함께 갱신 가능. 종료된 로그를 반환.
  Future<TrackingLog> stop({
    required String id,
    required DateTime endedAt,
    double? amount,
    String? note,
  });
}
