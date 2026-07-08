import '../entities/symptom.dart';

/// 증상 마스터 읽기 전용 저장소 (§3 C1/C2, §7.1 `symptoms`, §5.3 공개 읽기).
///
/// 실패 시 구현체는 `AppException` 계열(lib/core/error/app_exception.dart)을 던지거나
/// 스트림 error 이벤트로 전달한다.
abstract class SymptomRepository {
  /// 활성 증상 전체를 `order_index` 순으로 관찰(홈 그리드 — §11.7).
  Stream<List<Symptom>> watchAll();

  /// 활성 증상 전체 1회 조회.
  Future<List<Symptom>> getAll();

  /// id로 단건 조회. 없으면 null.
  Future<Symptom?> getById(String id);

  /// slug(딥링크 진입 — §3.3)로 단건 조회. 없으면 null.
  Future<Symptom?> getBySlug(String slug);

  /// 초성('ㅂㅇㅇ')·부분일치·별칭(aliases) 매칭 검색 (§11.8).
  ///
  /// 구현체는 각 후보에 대해
  /// `HangulChosung.matches(query, symptom.name, aliases: symptom.aliases)`
  /// (lib/core/utils/hangul_chosung.dart)로 필터링한다. 공백 질의는 빈 목록.
  Future<List<Symptom>> search(String query);
}
