// 이 서비스는 의존성이 많아 named 생성자로 주입한다. named 매개변수는 `_` 로 시작할 수
// 없어(언어 제약) private 필드에 대한 initializing formal(`this._x`)을 named 로 쓸 수
// 없으므로, 해당 lint의 제안은 이 파일에 적용 불가하다.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/repositories/support/personal_payloads.dart';
import 'package:agawaeuleo/data/supabase/supabase.dart';
import 'package:agawaeuleo/domain/repositories/auth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 개인기록 동기화 서비스 (§5.3 로컬 우선 → Supabase push).
///
/// 로컬 리포지토리가 `pending_ops`에 쌓은 연산을 **FIFO(생성순)**로 원격에 밀어넣는다.
/// 트리거는 세 가지다:
///   1. 앱/서비스 시작 시 1회(밀린 큐 정리 — §11.11 복원 후 동기화 포함),
///   2. `connectivity_plus` 온라인 전환,
///   3. 큐 길이 증가(새 로컬 쓰기 발생).
///
/// 실패는 `retry_count`를 올리고 지수 백오프 타이머로 재시도한다. 첫 실패에서 큐 처리를
/// 중단(head-of-line)해 FK 순서(babies → tracking_logs, §7.1)를 보존한다. 익명 세션이
/// 없으면 [AuthRepository.ensureSignedIn]으로 부트스트랩한 뒤 push한다(RLS는 세션 필요).
///
/// 미구성(원격 데이터소스 null)일 때는 아무 것도 하지 않는다 — 로컬 전용 모드.
class SyncService {
  SyncService({
    required PendingOpsDao pendingOps,
    required TrackingLogsDao trackingDao,
    required BabiesDao babiesDao,
    required FavoritesDao favoritesDao,
    required AuthRepository auth,
    TrackingRemoteDataSource? trackingRemote,
    BabyRemoteDataSource? babyRemote,
    FavoriteRemoteDataSource? favoriteRemote,
    Connectivity? connectivity,
  }) : _pendingOps = pendingOps,
       _trackingDao = trackingDao,
       _babiesDao = babiesDao,
       _favoritesDao = favoritesDao,
       _auth = auth,
       _trackingRemote = trackingRemote,
       _babyRemote = babyRemote,
       _favoriteRemote = favoriteRemote,
       _connectivity = connectivity ?? Connectivity();

  final PendingOpsDao _pendingOps;
  final TrackingLogsDao _trackingDao;
  final BabiesDao _babiesDao;
  final FavoritesDao _favoritesDao;
  final AuthRepository _auth;
  final TrackingRemoteDataSource? _trackingRemote;
  final BabyRemoteDataSource? _babyRemote;
  final FavoriteRemoteDataSource? _favoriteRemote;
  final Connectivity _connectivity;

  StreamSubscription<List<PendingOpRow>>? _queueSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _retryTimer;

  bool _started = false;
  bool _disposed = false;
  bool _isFlushing = false;
  bool _rerun = false;
  int _lastQueueLength = 0;

  /// 원격 대상이 있는지(구성됨). 세 원격은 같은 클라이언트에서 파생되어 all-or-nothing.
  bool get isConfigured => _trackingRemote != null;

  /// 리스너를 설치하고 초기 플러시를 예약한다(§5.3). 프로바이더 최초 생성 시 1회 호출.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    if (!isConfigured) return; // 로컬 전용: 동기화 대상 없음.

    _connSub = _connectivity.onConnectivityChanged.listen(
      (_) => unawaited(flush()),
    );
    _queueSub = _pendingOps.watchAll().listen((ops) {
      // 큐 길이가 늘어난 경우(새 로컬 쓰기)만 트리거 —
      // retry_count 증가/삭제로 인한 재방출로 무한 루프가 생기지 않게 한다.
      final grew = ops.length > _lastQueueLength;
      _lastQueueLength = ops.length;
      if (grew) unawaited(flush());
    });

    unawaited(flush());
  }

  /// 외부(main/테스트)에서 수동으로 플러시를 요청한다.
  Future<void> requestFlush() => flush();

  /// 큐를 1회 소진한다. 중복 실행은 병합한다(재진입 방지).
  Future<void> flush() async {
    if (_disposed || !isConfigured) return;
    if (_isFlushing) {
      _rerun = true;
      return;
    }
    _isFlushing = true;
    try {
      await _flushOnce();
    } finally {
      _isFlushing = false;
    }
    if (_rerun && !_disposed) {
      _rerun = false;
      await flush();
    }
  }

  Future<void> _flushOnce() async {
    if (!await _isOnline()) return;

    final ops = await _pendingOps.getPending();
    if (ops.isEmpty) return;

    // RLS는 세션을 요구한다. 세션 부트스트랩 실패(오프라인 등)면 다음 트리거로 미룬다.
    try {
      await _auth.ensureSignedIn();
    } on Object {
      _scheduleRetry(1);
      return;
    }

    for (final op in ops) {
      try {
        await _push(op);
        await _pendingOps.remove(op.id);
      } on Object {
        await _pendingOps.incrementRetry(op.id);
        // 첫 실패에서 중단: FIFO/FK 순서를 보존하고, 백오프로 재시도.
        _scheduleRetry(op.retryCount + 1);
        return;
      }
    }
  }

  Future<void> _push(PendingOpRow op) {
    final opType = PendingOpType.fromWire(op.opType);
    switch (SyncEntityType.fromWire(op.entityType)) {
      case SyncEntityType.trackingLog:
        return _pushTracking(op, opType);
      case SyncEntityType.baby:
        return _pushBaby(op, opType);
      case SyncEntityType.favorite:
        return _pushFavorite(op, opType);
    }
  }

  Future<void> _pushTracking(PendingOpRow op, PendingOpType opType) async {
    final remote = _trackingRemote!;
    if (opType == PendingOpType.delete) {
      await remote.delete(op.localId);
      return;
    }
    final log = decodeTrackingLog(op.payload);
    final saved = opType == PendingOpType.insert
        ? await remote.add(log)
        : await remote.update(log);
    // 서버 행 id는 로컬 id를 그대로 전송하므로 동일하지만, 매핑을 명시적으로 기록한다.
    await _trackingDao.setServerId(op.localId, saved.id);
  }

  Future<void> _pushBaby(PendingOpRow op, PendingOpType opType) async {
    final remote = _babyRemote!;
    if (opType == PendingOpType.delete) {
      await remote.delete(op.localId);
      return;
    }
    final baby = decodeBaby(op.payload);
    final saved = opType == PendingOpType.insert
        ? await remote.add(baby)
        : await remote.update(baby);
    await _babiesDao.setServerId(op.localId, saved.id);
  }

  Future<void> _pushFavorite(PendingOpRow op, PendingOpType opType) async {
    final remote = _favoriteRemote!;
    if (opType == PendingOpType.delete) {
      await remote.delete(op.localId);
      return;
    }
    // favorites는 insert만(수정 없음 — 토글은 insert/delete로 표현).
    final favorite = decodeFavorite(op.payload);
    final saved = await remote.add(favorite);
    await _favoritesDao.setServerId(op.localId, saved.id);
  }

  Future<bool> _isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } on Object {
      // 확인 자체가 실패하면 일단 시도(실제 실패는 push 단계에서 처리).
      return true;
    }
  }

  void _scheduleRetry(int attempt) {
    if (_disposed) return;
    _retryTimer?.cancel();
    final capped = attempt < 1 ? 1 : (attempt > 6 ? 6 : attempt);
    // 1s, 2s, 4s, ... 최대 60s.
    final grown = 1000 * (1 << (capped - 1));
    final delayMs = grown > 60000 ? 60000 : grown;
    _retryTimer = Timer(
      Duration(milliseconds: delayMs),
      () => unawaited(flush()),
    );
  }

  /// 리스너·타이머를 정리한다(프로바이더 dispose 시).
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    unawaited(_queueSub?.cancel());
    unawaited(_connSub?.cancel());
  }
}
