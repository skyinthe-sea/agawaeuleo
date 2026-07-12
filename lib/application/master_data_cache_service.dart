import 'dart:async';
import 'dart:convert';

import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/supabase/supabase.dart';
import 'package:drift/drift.dart';

/// 마스터 데이터 오프라인 캐시 동기화 (§5.3 캐싱 기능 — stale-while-revalidate).
///
/// 서버 `content_versions` 매니페스트를 읽어 로컬 `cache_meta` 버전과 비교하고,
/// **버전이 다른 데이터셋만** Supabase → Drift로 통째 재조회한다. 앱은 항상 Drift
/// 캐시에서 읽으므로(네트워크는 화면 진입마다 접촉하지 않음), 이 서비스가 캐시의
/// 신선도만 담당한다.
///
/// 기동:
///   - [start] — 부팅 1회 초기 동기화 + 매니페스트 **단일 realtime 구독**(앱이 열린
///     동안 서버 변경이 즉시 재검증을 트리거).
///   - [ensureFirstSync] — 스플래시에서 await(타임아웃 폴백)해 첫 실행 시 빈 화면
///     대신 채워진 홈을 보이게 한다.
///   - [refresh] — 당겨서 새로고침 강제 재검증.
///
/// 미구성(Supabase 없음)이면 모든 원격 의존이 null이라 완전 no-op이 된다(데모 모드는
/// 리포지토리가 픽스처로 처리).
class MasterDataCacheService {
  /// 의존은 위치 인자(초기화 형식)로 받는다 — 타입이 전부 달라 순서 오류는
  /// 타입체커가 잡고, 생성은 프로바이더 1곳에서만 한다. 미구성 시 각 인자는 null.
  MasterDataCacheService(
    this._cache,
    this._contentVersions,
    this._symptoms,
    this._symptomInfos,
    this._products,
  );

  final MasterCacheDao? _cache;
  final ContentVersionRemoteDataSource? _contentVersions;
  final SymptomRemoteDataSource? _symptoms;
  final SymptomInfoRemoteDataSource? _symptomInfos;
  final ProductRemoteDataSource? _products;

  /// 데이터셋 키 — 서버 매니페스트·로컬 `cache_meta`와 공유하는 문자열 계약.
  static const datasetSymptoms = 'symptoms';
  static const datasetSymptomInfos = 'symptom_infos';
  static const datasetProducts = 'products';

  StreamSubscription<Map<String, int>>? _manifestSub;
  Future<void>? _inFlight;
  Completer<void>? _firstSync;

  bool get _enabled =>
      _cache != null &&
      _contentVersions != null &&
      _symptoms != null &&
      _symptomInfos != null &&
      _products != null;

  /// 부팅 1회 기동 — 초기 재검증 + 매니페스트 실시간 구독.
  void start() {
    if (!_enabled) return;
    unawaited(_syncSafely());
    _manifestSub ??= _contentVersions!.watchVersions().listen(
      (versions) => unawaited(_syncSafely(remote: versions)),
      onError: (Object _, StackTrace _) {},
    );
  }

  /// 스플래시에서 await — **콜드 캐시(첫 실행)일 때만** 첫 동기화를 기다린다
  /// (빈 홈 방지). 이미 캐시가 있으면 막지 않고 즉시 반환하며(홈이 캐시로 바로 뜸)
  /// 재검증은 백그라운드로 돌린다. [timeout] 경과 시 조용히 진행(오프라인 폴백).
  Future<void> ensureFirstSync({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_enabled) return;
    final hasCache = await _cache!.getVersion(datasetSymptoms) != null;
    if (hasCache) {
      unawaited(_syncSafely());
      return;
    }
    final completer = _firstSync ??= Completer<void>();
    unawaited(_syncSafely());
    await completer.future.timeout(timeout, onTimeout: () {});
  }

  /// 강제 재검증(당겨서 새로고침).
  Future<void> refresh() => _syncSafely(force: true);

  /// realtime 구독 정리(프로바이더 dispose 시).
  void dispose() {
    _manifestSub?.cancel();
    _manifestSub = null;
  }

  Future<void> _syncSafely({Map<String, int>? remote, bool force = false}) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final run = _sync(
      remote: remote,
      force: force,
    ).catchError((Object _) {}).whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<void> _sync({Map<String, int>? remote, bool force = false}) async {
    if (!_enabled) return;
    try {
      final versions = remote ?? await _contentVersions!.fetchVersions();
      await _syncDataset(
        datasetSymptoms,
        versions[datasetSymptoms],
        force: force,
        pull: _pullSymptoms,
      );
      await _syncDataset(
        datasetSymptomInfos,
        versions[datasetSymptomInfos],
        force: force,
        pull: _pullSymptomInfos,
      );
      await _syncDataset(
        datasetProducts,
        versions[datasetProducts],
        force: force,
        pull: _pullProducts,
      );
    } finally {
      final completer = _firstSync;
      if (completer != null && !completer.isCompleted) completer.complete();
    }
  }

  /// 한 데이터셋 재검증 — 서버 버전이 로컬과 다르거나(또는 [force]) 로컬이 없으면
  /// [pull]로 재조회하고 로컬 버전을 갱신한다. 한 데이터셋 실패가 다른 데이터셋을
  /// 막지 않도록 개별 try로 감싼다.
  Future<void> _syncDataset(
    String dataset,
    int? remoteVersion, {
    required bool force,
    required Future<void> Function() pull,
  }) async {
    if (remoteVersion == null) return; // 매니페스트에 없음 → 스킵.
    try {
      final localVersion = await _cache!.getVersion(dataset);
      if (!force && localVersion == remoteVersion) return;
      await pull();
      await _cache.setVersion(dataset, remoteVersion, DateTime.now());
    } on Object {
      // 오프라인·일시 오류: 이번 재검증만 건너뛴다(Drift가 이전 스냅샷 유지).
    }
  }

  Future<void> _pullSymptoms() async {
    final rows = await _symptoms!.fetchActiveRows();
    await _cache!.replaceSymptoms([
      for (final row in rows)
        CachedSymptomsCompanion.insert(
          id: row['id'] as String,
          slug: row['slug'] as String,
          orderIndex: Value(_asInt(row['order_index'])),
          isActive: Value(row['is_active'] as bool? ?? true),
          data: jsonEncode(row),
        ),
    ]);
  }

  Future<void> _pullSymptomInfos() async {
    final rows = await _symptomInfos!.fetchLatestRowsPerSymptom();
    await _cache!.replaceSymptomInfos([
      for (final row in rows)
        CachedSymptomInfosCompanion.insert(
          symptomId: row['symptom_id'] as String,
          data: jsonEncode(row),
          updatedAt: parseDate(row['updated_at']),
        ),
    ]);
  }

  Future<void> _pullProducts() async {
    final rows = await _products!.fetchActiveRows();
    await _cache!.replaceProducts([
      for (final row in rows)
        CachedProductsCompanion.insert(
          id: row['id'] as String,
          symptomId: row['symptom_id'] as String,
          rankIndex: Value(_asInt(row['rank_index'])),
          isActive: Value(row['is_active'] as bool? ?? true),
          data: jsonEncode(row),
        ),
    ]);
  }

  static int _asInt(Object? value) => (value as num?)?.toInt() ?? 0;
}
