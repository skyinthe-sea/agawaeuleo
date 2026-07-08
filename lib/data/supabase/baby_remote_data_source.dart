import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/baby.dart';
import 'row_mappers.dart';
import 'supabase_error_mapper.dart';

/// 아기 프로필 원격 데이터소스 (§7.1 `babies`, §11.14). 본인 소유만(RLS `own babies`).
///
/// 쓰기 시 `user_id`는 현재 세션의 `auth.uid()`로 강제해 RLS `with check`를 항상 통과시킨다.
/// `id`/`created_at`은 로컬 우선(§5.3) 동기화를 위해 엔티티 값이 있으면 그대로 전송하고,
/// 없으면 DB 기본값(gen_random_uuid()/now())에 맡긴다. 선택된 아기 id 저장은 로컬 담당이므로
/// 여기서는 다루지 않는다(리포지토리).
class BabyRemoteDataSource {
  BabyRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'babies';

  SupabaseQueryBuilder get _from => _client.from(_table);

  String? get _uid => _client.auth.currentUser?.id;

  /// 본인 아기 목록을 `created_at` 순으로 관찰.
  Stream<List<Baby>> watchAll() => _from
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((rows) => rows.map(_fromRow).toList(growable: false))
      .mapErrorToAppException();

  /// 본인 아기 목록 1회 조회.
  Future<List<Baby>> getAll() async {
    try {
      final rows = await _from.select().order('created_at', ascending: true);
      return rows.map(_fromRow).toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// id로 단건 조회. 없으면 null.
  Future<Baby?> getById(String id) async {
    try {
      final row = await _from.select().eq('id', id).maybeSingle();
      return row == null ? null : _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 아기 추가. 저장된(서버 확정) 프로필을 반환.
  Future<Baby> add(Baby baby) async {
    try {
      final row = await _from.insert(_toInsert(baby)).select().single();
      return _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 아기 수정. 수정된 프로필을 반환.
  Future<Baby> update(Baby baby) async {
    try {
      final row = await _from
          .update(_toUpdate(baby))
          .eq('id', baby.id)
          .select()
          .single();
      return _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 아기 삭제(관련 기록은 on delete cascade — §7.1).
  Future<void> delete(String id) async {
    try {
      await _from.delete().eq('id', id);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  Baby _fromRow(Map<String, dynamic> row) => Baby(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    name: row['name'] as String,
    birthDate: parseDateOrNull(row['birth_date']),
    gender: BabyGender.fromWire(row['gender'] as String?),
    createdAt: parseDate(row['created_at']),
  );

  Map<String, dynamic> _toInsert(Baby baby) => {
    if (baby.id.isNotEmpty) 'id': baby.id,
    'user_id': _uid ?? baby.userId,
    'name': baby.name,
    'birth_date': baby.birthDate == null ? null : toDateOnly(baby.birthDate!),
    'gender': baby.gender.wire,
    'created_at': baby.createdAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _toUpdate(Baby baby) => {
    'name': baby.name,
    'birth_date': baby.birthDate == null ? null : toDateOnly(baby.birthDate!),
    'gender': baby.gender.wire,
  };
}
