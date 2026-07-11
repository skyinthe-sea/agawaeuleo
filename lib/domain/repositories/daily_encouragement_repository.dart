import '../entities/daily_encouragement.dart';

/// 오늘의 응원 문구 저장소 (홈 인사 하위 — 발주자 요청 기능, §7.1 공개 읽기 마스터 데이터).
///
/// 미구성(데모)·오프라인·빈 목록 시 구현체는 픽스처 목록으로 폴백한다(빈 화면 방지 —
/// §12.2 정신). 회전 인덱스 계산은 저장소 밖(프레젠테이션)에서 `DailyRotation`으로 한다.
abstract class DailyEncouragementRepository {
  /// 활성 응원 문구 전체를 `order_index` 오름차순으로 관찰.
  Stream<List<DailyEncouragement>> watchAll();

  /// 활성 응원 문구 전체 1회 조회(`order_index` 오름차순).
  Future<List<DailyEncouragement>> getAll();
}
