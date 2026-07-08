import 'package:agawaeuleo/core/error/app_exception.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/repositories/support/local_identity_store.dart';
import 'package:agawaeuleo/data/repositories/support/personal_payloads.dart';
import 'package:agawaeuleo/data/repositories/tracking_repository_impl.dart';
import 'package:agawaeuleo/domain/entities/tracking_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// §5.3 로컬 우선 쓰기 → 동기화 큐 계약을 리포지토리 레벨에서 검증.
///
/// 읽기는 로컬 Drift 스트림, 쓰기는 로컬 upsert 후 (구성 시)`pending_ops` 큐잉이다.
/// 로그인/연결과 무관하게 즉시 기록된다(§2-4).
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

  TrackingRepositoryImpl repo({bool syncEnabled = true}) =>
      TrackingRepositoryImpl(
        db.trackingLogsDao,
        db.pendingOpsDao,
        identity,
        syncEnabled: syncEnabled,
      );

  TrackingLog makeLog({
    String id = 't1',
    TrackingType type = TrackingType.feed,
    TrackingSubtype? subtype = TrackingSubtype.breast,
    double? amount,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    final t = startedAt ?? DateTime(2026, 7, 8, 10);
    return TrackingLog(
      id: id,
      userId: 'will-be-overwritten',
      type: type,
      subtype: subtype,
      amount: amount,
      startedAt: t,
      endedAt: endedAt,
      createdAt: t,
    );
  }

  test('add는 로컬에 upsert하고 insert 연산을 큐잉한다(로컬 우선)', () async {
    final saved = await repo().add(
      makeLog(endedAt: DateTime(2026, 7, 8, 10, 20), amount: 90),
    );

    // 로컬 행이 즉시 존재하고, user_id는 안정적 로컬 신원으로 통일된다.
    final expectedUid = await identity.ensureId();
    expect(saved.userId, expectedUid);
    final local = await db.trackingLogsDao.getById('t1');
    expect(local, isNotNull);
    expect(local!.userId, expectedUid);

    // pending_ops에 insert 연산 1건, payload가 원본으로 복원된다.
    final pending = await db.pendingOpsDao.getPending();
    expect(pending, hasLength(1));
    expect(pending.single.opType, PendingOpType.insert.wire);
    expect(pending.single.entityType, SyncEntityType.trackingLog.wire);
    expect(pending.single.localId, 't1');
    expect(decodeTrackingLog(pending.single.payload).id, 't1');
  });

  test('id가 비어 있으면 새 uuid를 생성해 저장한다', () async {
    final saved = await repo().add(makeLog(id: ''));
    expect(saved.id, isNotEmpty);
    expect(await db.trackingLogsDao.getById(saved.id), isNotNull);
  });

  test('syncEnabled=false면 로컬에만 저장하고 큐잉하지 않는다(로컬 전용)', () async {
    await repo(syncEnabled: false).add(makeLog());
    expect(await db.trackingLogsDao.getById('t1'), isNotNull);
    expect(await db.pendingOpsDao.getPending(), isEmpty);
  });

  test('delete는 미동기화 insert를 취소하고 delete 연산으로 대체한다(churn 완화)', () async {
    final r = repo();
    await r.add(makeLog());
    await r.delete('t1');

    // 로컬 행 제거.
    expect(await db.trackingLogsDao.getById('t1'), isNull);

    // 앞선 insert는 removeByLocalId로 취소되고 delete 1건만 남는다.
    final pending = await db.pendingOpsDao.getPending();
    expect(pending, hasLength(1));
    expect(pending.single.opType, PendingOpType.delete.wire);
    expect(pending.single.localId, 't1');
  });

  test('stop은 진행중 로그를 종료(ended_at 설정)하고 update를 큐잉한다', () async {
    final r = repo();
    await r.add(
      makeLog(type: TrackingType.sleep, subtype: null),
    ); // endedAt null = 진행중
    final endedAt = DateTime(2026, 7, 8, 11);

    final stopped = await r.stop(id: 't1', endedAt: endedAt, note: '기상');
    expect(stopped.endedAt, endedAt);
    expect(stopped.isInProgress, isFalse);
    expect(stopped.note, '기상');

    final local = await db.trackingLogsDao.getById('t1');
    expect(local!.endedAt, endedAt);

    // insert(add) → update(stop) 순서로 큐잉되어 있다.
    final pending = await db.pendingOpsDao.getPending();
    expect(pending.map((e) => e.opType), [
      PendingOpType.insert.wire,
      PendingOpType.update.wire,
    ]);
  });

  test('stop은 대상이 없으면 AppNotFoundException을 던진다', () async {
    await expectLater(
      repo().stop(id: 'missing', endedAt: DateTime(2026, 7, 8, 11)),
      throwsA(isA<AppNotFoundException>()),
    );
  });

  test('watchByDay는 로컬 스트림으로 당일 기록을 방출한다', () async {
    final r = repo();
    await r.add(makeLog(startedAt: DateTime(2026, 7, 8, 9)));
    await expectLater(
      r.watchByDay(day: DateTime(2026, 7, 8)),
      emits(
        predicate<List<TrackingLog>>(
          (l) => l.length == 1 && l.single.id == 't1',
        ),
      ),
    );
  });
}
