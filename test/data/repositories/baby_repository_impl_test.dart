import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/repositories/baby_repository_impl.dart';
import 'package:agawaeuleo/data/repositories/support/local_identity_store.dart';
import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:agawaeuleo/domain/entities/tracking_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// §11.14 아기 삭제 시 관련 기록 처리 계약을 검증한다.
///
/// 삭제 다이얼로그가 "기록도 함께 삭제"를 안내하므로, 로컬 기록은 즉시 사라지고
/// (고아 기록 0건) 원격 삭제는 기존 큐 패턴(`pending_ops`)으로 전파돼야 한다.
void main() {
  late AppDatabase db;
  late LocalIdentityStore identity;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.inMemory();
    identity = LocalIdentityStore();
  });

  tearDown(() async {
    await db.close();
  });

  BabyRepositoryImpl repo({bool syncEnabled = true}) => BabyRepositoryImpl(
    db.babiesDao,
    db.pendingOpsDao,
    identity,
    syncEnabled: syncEnabled,
  );

  Baby makeBaby({String id = 'baby-a', String name = '아가'}) => Baby(
    id: id,
    userId: 'local-user',
    name: name,
    createdAt: DateTime(2026, 7, 8),
  );

  TrackingLog makeLog({required String id, String? babyId}) {
    final t = DateTime(2026, 7, 8, 10);
    return TrackingLog(
      id: id,
      userId: 'local-user',
      babyId: babyId,
      type: TrackingType.feed,
      subtype: TrackingSubtype.formula,
      amount: 90,
      startedAt: t,
      endedAt: t.add(const Duration(minutes: 15)),
      createdAt: t,
    );
  }

  test('아기 삭제 시 해당 아기의 기록이 모두 사라져 고아 기록이 0건이다', () async {
    final r = repo();
    await r.add(makeBaby());
    await db.trackingLogsDao.upsert(makeLog(id: 'l1', babyId: 'baby-a'));
    await db.trackingLogsDao.upsert(makeLog(id: 'l2', babyId: 'baby-a'));
    // 다른 아기의 기록은 보존돼야 한다.
    await db.trackingLogsDao.upsert(makeLog(id: 'other', babyId: 'baby-b'));

    await r.delete('baby-a');

    expect(await db.babiesDao.getById('baby-a'), isNull);
    expect(await db.trackingLogsDao.getById('l1'), isNull);
    expect(await db.trackingLogsDao.getById('l2'), isNull);
    // 고아(삭제된 아기에 매인) 기록 0건.
    final remaining = await db.trackingLogsDao.countAll();
    expect(remaining, 1);
    expect(await db.trackingLogsDao.getById('other'), isNotNull);
  });

  test('아기 삭제 시 관련 기록의 원격 delete 연산이 큐잉된다(원격 전파)', () async {
    final r = repo();
    await r.add(makeBaby()); // insert(baby) 큐잉
    await db.trackingLogsDao.upsert(makeLog(id: 'l1', babyId: 'baby-a'));
    await db.trackingLogsDao.upsert(makeLog(id: 'l2', babyId: 'baby-a'));

    await r.delete('baby-a');

    final pending = await db.pendingOpsDao.getPending();
    // 아기 insert는 removeByLocalId로 취소되고, delete 연산만 남는다.
    final trackingDeletes = pending.where(
      (op) =>
          op.entityType == SyncEntityType.trackingLog.wire &&
          op.opType == PendingOpType.delete.wire,
    );
    expect(trackingDeletes.map((e) => e.localId), containsAll(['l1', 'l2']));

    final babyDeletes = pending.where(
      (op) =>
          op.entityType == SyncEntityType.baby.wire &&
          op.opType == PendingOpType.delete.wire,
    );
    expect(babyDeletes.map((e) => e.localId), ['baby-a']);
    // 아기 insert가 취소돼 baby 관련 큐는 delete 1건뿐이다.
    final babyOps = pending.where(
      (op) => op.entityType == SyncEntityType.baby.wire,
    );
    expect(babyOps, hasLength(1));
  });

  test('syncEnabled=false면 로컬 기록만 지우고 큐잉하지 않는다', () async {
    final r = repo(syncEnabled: false);
    await r.add(makeBaby());
    await db.trackingLogsDao.upsert(makeLog(id: 'l1', babyId: 'baby-a'));

    await r.delete('baby-a');

    expect(await db.trackingLogsDao.getById('l1'), isNull);
    expect(await db.pendingOpsDao.getPending(), isEmpty);
  });
}
