import 'dart:async';

import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/repositories/support/id_generator.dart';
import 'package:agawaeuleo/data/repositories/support/local_identity_store.dart';
import 'package:agawaeuleo/data/repositories/support/personal_payloads.dart';
import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:agawaeuleo/domain/repositories/baby_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [BabyRepository] 구현 — **로컬 우선 쓰기 → 동기화 큐**(§5.3, §11.14).
///
/// 프로필 CRUD는 [BabiesDao](로컬)에 먼저 반영하고 구성 시 `pending_ops`에 큐잉한다.
/// "선택된 아기"(다둥이 전환 — §11.10)는 서버가 아니라 기기 로컬 상태이므로
/// `shared_preferences`로 관리한다([watchSelectedBabyId]/[selectBaby]).
class BabyRepositoryImpl implements BabyRepository {
  BabyRepositoryImpl(
    this._dao,
    this._pendingOps,
    this._identity, {
    this.syncEnabled = true,
  });

  final BabiesDao _dao;
  final PendingOpsDao _pendingOps;
  final LocalIdentityStore _identity;

  /// 구성됨(Supabase) 여부. false면 큐잉하지 않고 로컬 전용으로만 동작.
  final bool syncEnabled;

  /// 선택된 아기 id `shared_preferences` 키.
  static const String selectedKey = 'personal.selected_baby_id';

  final StreamController<String?> _selectedController =
      StreamController<String?>.broadcast();
  String? _selectedCache;
  bool _selectedLoaded = false;

  // ── 읽기 (로컬 스트림) ─────────────────────────────────────────────
  @override
  Stream<List<Baby>> watchAll() => _dao.watchAll();

  @override
  Future<List<Baby>> getAll() => _dao.getAll();

  @override
  Future<Baby?> getById(String id) => _dao.getById(id);

  // ── 쓰기 (로컬 우선 → 큐) ──────────────────────────────────────────
  @override
  Future<Baby> add(Baby baby) async {
    final uid = await _identity.ensureId();
    final prepared = baby.copyWith(
      id: baby.id.isEmpty ? newUuidV4() : baby.id,
      userId: uid,
    );
    await _dao.upsert(prepared);
    await _enqueue(PendingOpType.insert, prepared);
    return prepared;
  }

  @override
  Future<Baby> update(Baby baby) async {
    final uid = await _identity.ensureId();
    final prepared = baby.copyWith(userId: uid);
    await _dao.upsert(prepared);
    await _enqueue(PendingOpType.update, prepared);
    return prepared;
  }

  @override
  Future<void> delete(String id) async {
    // §11.14 아기 삭제 시 관련 기록도 함께 삭제한다(삭제 다이얼로그 안내와 일치).
    // 로컬은 FK cascade가 없으므로 명시적으로 지우고, 서버 전파는 아래 큐로 처리한다.
    final trackingDao = _dao.attachedDatabase.trackingLogsDao;
    final orphanLogIds = await trackingDao.deleteByBabyId(id);
    await _dao.deleteById(id);
    // 삭제된 아기가 선택돼 있었다면 선택 해제(§11.10 전환 일관성).
    if (await getSelectedBabyId() == id) {
      await selectBaby(null);
    }
    if (!syncEnabled) return;
    // 관련 기록의 원격 삭제 전파 — 기존 큐 패턴 준수(미동기화 큐 취소 → delete 연산).
    for (final logId in orphanLogIds) {
      await _pendingOps.removeByLocalId(logId);
      await _pendingOps.enqueue(
        opType: PendingOpType.delete,
        entityType: SyncEntityType.trackingLog,
        localId: logId,
        payload: '',
      );
    }
    await _pendingOps.removeByLocalId(id);
    await _pendingOps.enqueue(
      opType: PendingOpType.delete,
      entityType: SyncEntityType.baby,
      localId: id,
      payload: '',
    );
  }

  // ── 선택된 아기 (로컬 상태) ────────────────────────────────────────
  @override
  Stream<String?> watchSelectedBabyId() async* {
    yield await getSelectedBabyId();
    yield* _selectedController.stream;
  }

  @override
  Future<String?> getSelectedBabyId() async {
    if (_selectedLoaded) return _selectedCache;
    final prefs = await SharedPreferences.getInstance();
    _selectedCache = prefs.getString(selectedKey);
    _selectedLoaded = true;
    return _selectedCache;
  }

  @override
  Future<void> selectBaby(String? babyId) async {
    final prefs = await SharedPreferences.getInstance();
    if (babyId == null) {
      await prefs.remove(selectedKey);
    } else {
      await prefs.setString(selectedKey, babyId);
    }
    _selectedCache = babyId;
    _selectedLoaded = true;
    _selectedController.add(babyId);
  }

  Future<void> _enqueue(PendingOpType opType, Baby baby) async {
    if (!syncEnabled) return;
    await _pendingOps.enqueue(
      opType: opType,
      entityType: SyncEntityType.baby,
      localId: baby.id,
      payload: encodeBaby(baby),
    );
  }
}
