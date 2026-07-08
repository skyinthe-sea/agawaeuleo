import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/favorite.dart';
import 'row_mappers.dart';
import 'supabase_error_mapper.dart';

/// 즐겨찾기 원격 데이터소스 (§7.1 `favorites`, §11.15). 본인 소유만(RLS `own favorites`).
///
/// `unique(user_id, target_type, target_id)`(§7.1)로 대상당 최대 1행이 보장된다. 하트 토글
/// (조회 → 삽입/삭제 조합)은 리포지토리가 [getByTarget]+[add]/[deleteByTarget]로 구성한다.
/// 쓰기 시 `user_id`는 현재 세션의 `auth.uid()`로 강제한다.
class FavoriteRemoteDataSource {
  FavoriteRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'favorites';

  SupabaseQueryBuilder get _from => _client.from(_table);

  String? get _uid => _client.auth.currentUser?.id;

  /// 본인 즐겨찾기 전체를 `created_at` 역순으로 관찰.
  Stream<List<Favorite>> watchAll() => _from
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(_fromRow).toList(growable: false))
      .mapErrorToAppException();

  /// 본인 즐겨찾기 전체 1회 조회.
  Future<List<Favorite>> getAll() async {
    try {
      final rows = await _from.select().order('created_at', ascending: false);
      return rows.map(_fromRow).toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 특정 대상의 즐겨찾기 행 1회 조회. 없으면 null(= 미즐겨찾기).
  Future<Favorite?> getByTarget({
    required FavoriteTargetType targetType,
    required String targetId,
  }) async {
    try {
      final row = await _from
          .select()
          .eq('target_type', targetType.wire)
          .eq('target_id', targetId)
          .maybeSingle();
      return row == null ? null : _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 즐겨찾기 추가. 저장된(서버 확정) 행을 반환. (중복 삽입은 unique 제약으로 실패하므로
  /// 리포지토리는 토글 시 존재 여부를 먼저 확인한다.)
  Future<Favorite> add(Favorite favorite) async {
    try {
      final row = await _from.insert(_toInsert(favorite)).select().single();
      return _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// id로 즐겨찾기 삭제.
  Future<void> delete(String id) async {
    try {
      await _from.delete().eq('id', id);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 대상(target_type+target_id)으로 즐겨찾기 삭제(토글 해제용).
  Future<void> deleteByTarget({
    required FavoriteTargetType targetType,
    required String targetId,
  }) async {
    try {
      await _from
          .delete()
          .eq('target_type', targetType.wire)
          .eq('target_id', targetId);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  Favorite _fromRow(Map<String, dynamic> row) => Favorite(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    targetType: FavoriteTargetType.fromWire(row['target_type'] as String),
    targetId: row['target_id'] as String,
    createdAt: parseDate(row['created_at']),
  );

  Map<String, dynamic> _toInsert(Favorite favorite) => {
    if (favorite.id.isNotEmpty) 'id': favorite.id,
    'user_id': _uid ?? favorite.userId,
    'target_type': favorite.targetType.wire,
    'target_id': favorite.targetId,
    'created_at': favorite.createdAt.toUtc().toIso8601String(),
  };
}
