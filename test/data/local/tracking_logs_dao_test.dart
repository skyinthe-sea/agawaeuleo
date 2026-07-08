import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/domain/entities/tracking_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// §11.10~11.11 로컬 우선 기록 저장소(Drift) — in-memory CRUD + 진행중 타이머.
void main() {
  late AppDatabase db;
  late TrackingLogsDao dao;

  setUp(() {
    db = AppDatabase.inMemory();
    dao = db.trackingLogsDao;
  });

  tearDown(() async {
    await db.close();
  });

  TrackingLog makeLog({
    String id = 't1',
    String userId = 'local-user',
    String? babyId,
    TrackingType type = TrackingType.feed,
    TrackingSubtype? subtype = TrackingSubtype.breast,
    double? amount,
    String? note,
    required DateTime startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
  }) => TrackingLog(
    id: id,
    userId: userId,
    babyId: babyId,
    type: type,
    subtype: subtype,
    amount: amount,
    note: note,
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: createdAt ?? startedAt,
  );

  group('CRUD', () {
    test('upsert 후 getById가 저장한 값을 그대로 돌려준다', () async {
      final started = DateTime(2026, 7, 8, 9, 30);
      final log = makeLog(
        babyId: 'baby-a',
        subtype: TrackingSubtype.formula,
        amount: 120,
        note: '아침 수유',
        startedAt: started,
        endedAt: started.add(const Duration(minutes: 15)),
      );

      await dao.upsert(log);
      final loaded = await dao.getById('t1');

      expect(loaded, isNotNull);
      expect(loaded!.id, 't1');
      expect(loaded.userId, 'local-user');
      expect(loaded.babyId, 'baby-a');
      expect(loaded.type, TrackingType.feed);
      expect(loaded.subtype, TrackingSubtype.formula);
      expect(loaded.amount, 120);
      expect(loaded.note, '아침 수유');
      expect(loaded.startedAt, started);
      expect(loaded.endedAt, started.add(const Duration(minutes: 15)));
      expect(loaded.isInProgress, isFalse);
      expect(loaded.duration, const Duration(minutes: 15));
    });

    test('같은 id로 upsert하면 갱신되고 행이 늘지 않는다', () async {
      final started = DateTime(2026, 7, 8, 9);
      await dao.upsert(makeLog(startedAt: started, amount: 100, note: '초안'));
      await dao.upsert(makeLog(startedAt: started, amount: 200, note: '수정'));

      final loaded = await dao.getById('t1');
      expect(loaded!.amount, 200);
      expect(loaded.note, '수정');

      final all = await db.select(db.trackingLogs).get();
      expect(all, hasLength(1));
    });

    test('getById는 없는 id에 대해 null', () async {
      expect(await dao.getById('nope'), isNull);
    });

    test('deleteById가 대상 행을 제거한다', () async {
      await dao.upsert(makeLog(startedAt: DateTime(2026, 7, 8, 9)));
      final removed = await dao.deleteById('t1');
      expect(removed, 1);
      expect(await dao.getById('t1'), isNull);
    });

    test('setServerId가 동기화 서버 uuid를 기록한다', () async {
      await dao.upsert(makeLog(startedAt: DateTime(2026, 7, 8, 9)));
      await dao.setServerId('t1', 'server-uuid-123');

      final row = await (db.select(
        db.trackingLogs,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(row.serverId, 'server-uuid-123');
    });
  });

  group('일자별 조회 (§11.10 타임라인)', () {
    test('getByDay는 같은 날짜만, started_at 역순으로, babyId로 스코프한다', () async {
      final day = DateTime(2026, 7, 8);
      await dao.upsert(
        makeLog(id: 'a', babyId: 'baby-a', startedAt: DateTime(2026, 7, 8, 8)),
      );
      await dao.upsert(
        makeLog(id: 'b', babyId: 'baby-a', startedAt: DateTime(2026, 7, 8, 20)),
      );
      await dao.upsert(
        makeLog(id: 'c', babyId: 'baby-b', startedAt: DateTime(2026, 7, 8, 12)),
      );
      // 다른 날짜(경계 밖) — 제외되어야 한다.
      await dao.upsert(
        makeLog(id: 'd', babyId: 'baby-a', startedAt: DateTime(2026, 7, 9, 1)),
      );

      final forBabyA = await dao.getByDay(day: day, babyId: 'baby-a');
      expect(forBabyA.map((e) => e.id), ['b', 'a']); // 20시 → 8시

      final all = await dao.getByDay(day: day);
      expect(all.map((e) => e.id), ['b', 'c', 'a']); // 20 → 12 → 8, d는 다음날
    });
  });

  group('진행중 타이머 복원 (§11.11)', () {
    test('getInProgress는 ended_at IS NULL 기록만 돌려준다', () async {
      final t = DateTime(2026, 7, 8, 10);
      final open = makeLog(
        id: 'open',
        type: TrackingType.sleep,
        subtype: null,
        startedAt: t,
        // endedAt 생략 = null = 진행중
      );
      final done = makeLog(
        id: 'done',
        startedAt: t,
        endedAt: t.add(const Duration(hours: 1)),
      );
      await dao.upsert(open);
      await dao.upsert(done);

      final inProgress = await dao.getInProgress();
      expect(inProgress.map((e) => e.id), ['open']);
      expect(inProgress.single.isInProgress, isTrue);

      // 타이머 종료 → 더 이상 진행중이 아니다.
      await dao.upsert(open.copyWith(endedAt: t.add(const Duration(hours: 2))));
      expect(await dao.getInProgress(), isEmpty);
    });

    test('getInProgress는 babyId로 스코프한다', () async {
      final t = DateTime(2026, 7, 8, 10);
      await dao.upsert(
        makeLog(
          id: 'a',
          babyId: 'baby-a',
          type: TrackingType.sleep,
          subtype: null,
          startedAt: t,
        ),
      );
      await dao.upsert(
        makeLog(
          id: 'b',
          babyId: 'baby-b',
          type: TrackingType.sleep,
          subtype: null,
          startedAt: t,
        ),
      );
      final forA = await dao.getInProgress(babyId: 'baby-a');
      expect(forA.map((e) => e.id), ['a']);
    });

    test('watchInProgress의 최초 방출이 현재 진행중 상태를 반영한다', () async {
      final t = DateTime(2026, 7, 8, 10);
      await dao.upsert(
        makeLog(
          id: 'open',
          type: TrackingType.sleep,
          subtype: null,
          startedAt: t,
        ),
      );
      await dao.upsert(
        makeLog(
          id: 'done',
          startedAt: t,
          endedAt: t.add(const Duration(hours: 1)),
        ),
      );

      await expectLater(
        dao.watchInProgress(),
        emits(
          predicate<List<TrackingLog>>(
            (l) => l.length == 1 && l.single.id == 'open',
          ),
        ),
      );
    });
  });
}
