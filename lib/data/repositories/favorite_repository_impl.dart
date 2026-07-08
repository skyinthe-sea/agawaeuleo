import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/repositories/support/id_generator.dart';
import 'package:agawaeuleo/data/repositories/support/local_identity_store.dart';
import 'package:agawaeuleo/data/repositories/support/personal_payloads.dart';
import 'package:agawaeuleo/domain/entities/favorite.dart';
import 'package:agawaeuleo/domain/repositories/favorite_repository.dart';

/// [FavoriteRepository] 구현 — **로컬 우선 쓰기 → 동기화 큐**(§5.3, §11.9/§11.15).
///
/// 하트 토글은 로컬 [FavoritesDao]에서 대상 존재 여부를 확인해 추가/삭제를 결정하고,
/// 로컬 반영 후 구성 시 `pending_ops`에 큐잉한다. 상태 관찰([watchIsFavorite])도 로컬
/// 스트림이라 오프라인·비로그인에서도 즉시 반응한다(§2-4).
///
/// 로컬 유니크 제약 `(userId, targetType, targetId)`(로컬 테이블) 및 조회에는
/// [LocalIdentityStore]의 안정적 로컬 게스트 id를 사용한다.
class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl(
    this._dao,
    this._pendingOps,
    this._identity, {
    this.syncEnabled = true,
  });

  final FavoritesDao _dao;
  final PendingOpsDao _pendingOps;
  final LocalIdentityStore _identity;

  /// 구성됨(Supabase) 여부. false면 큐잉하지 않고 로컬 전용으로만 동작.
  final bool syncEnabled;

  @override
  Stream<List<Favorite>> watchAll() => _dao.watchAll();

  @override
  Future<List<Favorite>> getAll() => _dao.getAll();

  @override
  Stream<bool> watchIsFavorite({
    required FavoriteTargetType targetType,
    required String targetId,
  }) => Stream<String>.fromFuture(_identity.ensureId()).asyncExpand(
    (uid) => _dao
        .watchByTarget(userId: uid, targetType: targetType, targetId: targetId)
        .map((favorite) => favorite != null),
  );

  @override
  Future<bool> isFavorite({
    required FavoriteTargetType targetType,
    required String targetId,
  }) async {
    final uid = await _identity.ensureId();
    final existing = await _dao.getByTarget(
      userId: uid,
      targetType: targetType,
      targetId: targetId,
    );
    return existing != null;
  }

  @override
  Future<bool> toggle({
    required FavoriteTargetType targetType,
    required String targetId,
  }) async {
    final uid = await _identity.ensureId();
    final existing = await _dao.getByTarget(
      userId: uid,
      targetType: targetType,
      targetId: targetId,
    );

    if (existing != null) {
      // 즐겨찾기 해제.
      await _dao.deleteByTarget(
        userId: uid,
        targetType: targetType,
        targetId: targetId,
      );
      if (syncEnabled) {
        // 미동기화 insert가 큐에 있으면 취소, 아니면 서버 delete로 처리.
        await _pendingOps.removeByLocalId(existing.id);
        await _pendingOps.enqueue(
          opType: PendingOpType.delete,
          entityType: SyncEntityType.favorite,
          localId: existing.id,
          payload: '',
        );
      }
      return false;
    }

    // 즐겨찾기 추가.
    final favorite = Favorite(
      id: newUuidV4(),
      userId: uid,
      targetType: targetType,
      targetId: targetId,
      createdAt: DateTime.now(),
    );
    await _dao.upsert(favorite);
    if (syncEnabled) {
      await _pendingOps.enqueue(
        opType: PendingOpType.insert,
        entityType: SyncEntityType.favorite,
        localId: favorite.id,
        payload: encodeFavorite(favorite),
      );
    }
    return true;
  }
}
