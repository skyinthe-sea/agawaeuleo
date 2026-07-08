import 'package:agawaeuleo/data/local/local.dart';
import 'package:flutter_test/flutter_test.dart';

/// §5.3 동기화 큐(`pending_ops`) DAO — FIFO 순서, 제거, 재시도 카운트.
void main() {
  late AppDatabase db;
  late PendingOpsDao dao;

  setUp(() {
    db = AppDatabase.inMemory();
    dao = db.pendingOpsDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> enqueue({
    required PendingOpType op,
    required SyncEntityType entity,
    required String localId,
    String payload = '{}',
    DateTime? createdAt,
  }) => dao.enqueue(
    opType: op,
    entityType: entity,
    localId: localId,
    payload: payload,
    createdAt: createdAt,
  );

  test('getPending은 created_at 오름차순(FIFO)으로 반환한다', () async {
    final base = DateTime(2026, 7, 8, 12);
    // 삽입 순서와 created_at 순서를 일부러 어긋나게 한다.
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.trackingLog,
      localId: 'later',
      createdAt: base.add(const Duration(seconds: 2)),
    );
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.baby,
      localId: 'earliest',
      createdAt: base,
    );
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.favorite,
      localId: 'latest',
      createdAt: base.add(const Duration(seconds: 3)),
    );

    final pending = await dao.getPending();
    expect(pending.map((e) => e.localId), ['earliest', 'later', 'latest']);
  });

  test('created_at가 같으면 삽입 순서(id 오름차순)로 타이브레이크한다', () async {
    final at = DateTime(2026, 7, 8, 12);
    final firstId = await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.baby,
      localId: 'baby-1',
      createdAt: at,
    );
    final secondId = await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.trackingLog,
      localId: 'log-1',
      createdAt: at,
    );
    expect(secondId, greaterThan(firstId));

    final pending = await dao.getPending();
    expect(pending.map((e) => e.localId), ['baby-1', 'log-1']);
  });

  test('enqueue가 opType/entityType/payload를 그대로 보존한다', () async {
    await enqueue(
      op: PendingOpType.update,
      entity: SyncEntityType.trackingLog,
      localId: 'log-9',
      payload: '{"id":"log-9","amount":120}',
    );
    final row = (await dao.getPending()).single;
    expect(row.opType, PendingOpType.update.wire);
    expect(row.entityType, SyncEntityType.trackingLog.wire);
    expect(row.localId, 'log-9');
    expect(row.payload, '{"id":"log-9","amount":120}');
    expect(row.retryCount, 0);
    // wire 문자열이 enum으로 왕복 복원된다.
    expect(PendingOpType.fromWire(row.opType), PendingOpType.update);
    expect(SyncEntityType.fromWire(row.entityType), SyncEntityType.trackingLog);
  });

  test('remove는 해당 큐 항목만 제거한다(동기화 성공 경로)', () async {
    final keepId = await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.baby,
      localId: 'keep',
    );
    final dropId = await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.baby,
      localId: 'drop',
    );

    expect(await dao.remove(dropId), 1);
    final pending = await dao.getPending();
    expect(pending.map((e) => e.id), [keepId]);
  });

  test('removeByLocalId는 대상 엔티티의 모든 큐 항목을 취소한다(삭제 churn 완화)', () async {
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.favorite,
      localId: 'fav-x',
    );
    await enqueue(
      op: PendingOpType.update,
      entity: SyncEntityType.favorite,
      localId: 'fav-x',
    );
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.favorite,
      localId: 'fav-y',
    );

    final removed = await dao.removeByLocalId('fav-x');
    expect(removed, 2);
    final pending = await dao.getPending();
    expect(pending.map((e) => e.localId), ['fav-y']);
  });

  test('incrementRetry가 재시도 횟수를 누적한다(백오프 재시도 경로)', () async {
    final id = await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.trackingLog,
      localId: 'log-r',
    );

    await dao.incrementRetry(id);
    await dao.incrementRetry(id);

    final row = (await dao.getPending()).single;
    expect(row.retryCount, 2);
  });

  test('clear가 큐 전체를 비운다', () async {
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.baby,
      localId: 'a',
    );
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.baby,
      localId: 'b',
    );
    expect(await dao.clear(), 2);
    expect(await dao.getPending(), isEmpty);
  });

  test('watchAll의 최초 방출이 현재 큐(FIFO)를 반영한다', () async {
    final base = DateTime(2026, 7, 8, 12);
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.baby,
      localId: 'first',
      createdAt: base,
    );
    await enqueue(
      op: PendingOpType.insert,
      entity: SyncEntityType.trackingLog,
      localId: 'second',
      createdAt: base.add(const Duration(seconds: 1)),
    );

    await expectLater(
      dao.watchAll(),
      emits(
        predicate<List<PendingOpRow>>(
          (rows) => rows.map((e) => e.localId).join(',') == 'first,second',
        ),
      ),
    );
  });
}
