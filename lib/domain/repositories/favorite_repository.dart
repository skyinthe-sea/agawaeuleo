import '../entities/favorite.dart';

/// 즐겨찾기 저장소 (§3 C5, §7.1 `favorites`, §11.15). 로컬 + 계정 동기화.
///
/// 실패 시 구현체는 `AppException` 계열을 던지거나 스트림 error 이벤트로 전달한다.
abstract class FavoriteRepository {
  /// 본인 즐겨찾기 전체를 `created_at` 역순으로 관찰.
  Stream<List<Favorite>> watchAll();

  /// 본인 즐겨찾기 전체 1회 조회.
  Future<List<Favorite>> getAll();

  /// 특정 대상의 즐겨찾기 여부 관찰(하트 토글 상태 — §11.9/§11.15).
  Stream<bool> watchIsFavorite({
    required FavoriteTargetType targetType,
    required String targetId,
  });

  /// 특정 대상의 즐겨찾기 여부 1회 조회.
  Future<bool> isFavorite({
    required FavoriteTargetType targetType,
    required String targetId,
  });

  /// 즐겨찾기 토글. 토글 후 최종 상태 반환(true = 즐겨찾기됨).
  Future<bool> toggle({
    required FavoriteTargetType targetType,
    required String targetId,
  });
}
