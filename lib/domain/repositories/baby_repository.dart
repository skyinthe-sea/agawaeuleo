import '../entities/baby.dart';

/// 아기 프로필 저장소 (§3 S3, §7.1 `babies`, §11.14). CRUD + 선택된 아기 관리.
///
/// 실패 시 구현체는 `AppException` 계열을 던지거나 스트림 error 이벤트로 전달한다.
abstract class BabyRepository {
  /// 본인 소유 아기 목록을 `created_at` 순으로 관찰.
  Stream<List<Baby>> watchAll();

  /// 본인 소유 아기 목록 1회 조회.
  Future<List<Baby>> getAll();

  /// id로 단건 조회. 없으면 null.
  Future<Baby?> getById(String id);

  /// 아기 추가. 저장된(서버 id 확정) 프로필을 반환.
  Future<Baby> add(Baby baby);

  /// 아기 수정. 수정된 프로필을 반환.
  Future<Baby> update(Baby baby);

  /// 아기 삭제(§11.14). 관련 기록도 함께 삭제한다 — 로컬은 일괄 삭제하고,
  /// 원격은 `pending_ops` 큐로 전파(서버는 on delete cascade — §7.1)한다.
  Future<void> delete(String id);

  /// 현재 선택된 아기 id 관찰(다둥이 전환 — §11.10). 로컬 저장. 없으면 null.
  Stream<String?> watchSelectedBabyId();

  /// 현재 선택된 아기 id 1회 조회. 없으면 null.
  Future<String?> getSelectedBabyId();

  /// 선택된 아기 지정(null이면 선택 해제).
  Future<void> selectBaby(String? babyId);
}
