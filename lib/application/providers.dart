import 'package:agawaeuleo/application/sync_service.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/repositories/repositories.dart';
import 'package:agawaeuleo/data/supabase/supabase.dart';
import 'package:agawaeuleo/domain/repositories/repositories.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'providers.g.dart';

/// 앱 전역 의존성 배선 (§5.2 레이어, §5.3 데이터 소스 원칙).
///
/// 모든 프로바이더는 `riverpod_annotation` 코드젠 스타일(function provider)이며
/// `keepAlive`로 앱 수명 동안 유지된다. **미구성 가드**: [SupabaseBootstrap]이 초기화되지
/// 않았으면(`supabaseUrl` 비어있음/오프라인) 원격 데이터소스 프로바이더가 `null`을 내고,
/// 리포지토리는 마스터 데이터를 픽스처로, 개인기록을 로컬 전용으로 처리한다.
///
/// 통합 단계 주의:
///   - `main()`은 `runApp` 이전에 `SupabaseBootstrap.ensureInitialized()`를 await 해야
///     [supabaseClientProvider]가 올바른 값을 캐시한다(프로바이더는 최초 build 시 정적
///     `isInitialized`를 읽는다).
///   - 동기화를 확실히 기동하려면 시작 시 [syncServiceProvider]를 한 번 read 한다(개인기록
///     리포지토리 프로바이더가 이미 이를 watch 하므로, 해당 리포지토리를 쓰면 자동 기동됨).

// ── 인프라 ────────────────────────────────────────────────────────────

/// 로컬 우선 저장소(Drift) 단일 인스턴스.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

/// 초기화된 Supabase 클라이언트. 미구성/미초기화면 null(원격 접근 금지 신호).
@Riverpod(keepAlive: true)
SupabaseClient? supabaseClient(Ref ref) =>
    SupabaseBootstrap.isInitialized ? Supabase.instance.client : null;

// ── 로컬 DAO ─────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
TrackingLogsDao trackingLogsDao(Ref ref) =>
    ref.watch(appDatabaseProvider).trackingLogsDao;

@Riverpod(keepAlive: true)
BabiesDao babiesDao(Ref ref) => ref.watch(appDatabaseProvider).babiesDao;

@Riverpod(keepAlive: true)
FavoritesDao favoritesDao(Ref ref) =>
    ref.watch(appDatabaseProvider).favoritesDao;

@Riverpod(keepAlive: true)
RecentSearchesDao recentSearchesDao(Ref ref) =>
    ref.watch(appDatabaseProvider).recentSearchesDao;

@Riverpod(keepAlive: true)
PendingOpsDao pendingOpsDao(Ref ref) =>
    ref.watch(appDatabaseProvider).pendingOpsDao;

/// 로컬 우선 개인기록의 안정적 소유자 식별자(§5.3, 세션 독립).
@Riverpod(keepAlive: true)
LocalIdentityStore localIdentityStore(Ref ref) => LocalIdentityStore();

// ── 원격 데이터소스(구성 시에만 생성, 아니면 null) ───────────────────────

@Riverpod(keepAlive: true)
AuthDataSource? authDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : AuthDataSource(client);
}

@Riverpod(keepAlive: true)
SymptomRemoteDataSource? symptomRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SymptomRemoteDataSource(client);
}

@Riverpod(keepAlive: true)
SymptomInfoRemoteDataSource? symptomInfoRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SymptomInfoRemoteDataSource(client);
}

@Riverpod(keepAlive: true)
ProductRemoteDataSource? productRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : ProductRemoteDataSource(client);
}

@Riverpod(keepAlive: true)
AppConfigRemoteDataSource? appConfigRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : AppConfigRemoteDataSource(client);
}

@Riverpod(keepAlive: true)
BabyRemoteDataSource? babyRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : BabyRemoteDataSource(client);
}

@Riverpod(keepAlive: true)
TrackingRemoteDataSource? trackingRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : TrackingRemoteDataSource(client);
}

@Riverpod(keepAlive: true)
FavoriteRemoteDataSource? favoriteRemoteDataSource(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : FavoriteRemoteDataSource(client);
}

// ── 마스터 데이터 리포지토리(구성 시 Supabase, 아니면 픽스처) ─────────────

@Riverpod(keepAlive: true)
SymptomRepository symptomRepository(Ref ref) =>
    SymptomRepositoryImpl(ref.watch(symptomRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
SymptomInfoRepository symptomInfoRepository(Ref ref) =>
    SymptomInfoRepositoryImpl(ref.watch(symptomInfoRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
ProductRepository productRepository(Ref ref) =>
    ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
AppConfigRepository appConfigRepository(Ref ref) =>
    AppConfigRepositoryImpl(ref.watch(appConfigRemoteDataSourceProvider));

// ── 인증 리포지토리 ──────────────────────────────────────────────────

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  ref.watch(localIdentityStoreProvider),
  ref.watch(authDataSourceProvider),
);

// ── 최근 검색어(로컬 전용) ────────────────────────────────────────────

@Riverpod(keepAlive: true)
RecentSearchRepository recentSearchRepository(Ref ref) =>
    RecentSearchRepository(ref.watch(recentSearchesDaoProvider));

// ── 개인기록 리포지토리(로컬 우선 → 동기화 큐) ──────────────────────────
//
// 동기화가 가능한지(`syncEnabled`)는 초기화된 Supabase 클라이언트 유무로 판단한다.
// 각 프로바이더는 [syncServiceProvider]를 watch 해 최초 사용 시 동기화 서비스를 기동한다.

@Riverpod(keepAlive: true)
TrackingRepository trackingRepository(Ref ref) {
  ref.watch(syncServiceProvider);
  return TrackingRepositoryImpl(
    ref.watch(trackingLogsDaoProvider),
    ref.watch(pendingOpsDaoProvider),
    ref.watch(localIdentityStoreProvider),
    syncEnabled: ref.watch(supabaseClientProvider) != null,
  );
}

@Riverpod(keepAlive: true)
BabyRepository babyRepository(Ref ref) {
  ref.watch(syncServiceProvider);
  return BabyRepositoryImpl(
    ref.watch(babiesDaoProvider),
    ref.watch(pendingOpsDaoProvider),
    ref.watch(localIdentityStoreProvider),
    syncEnabled: ref.watch(supabaseClientProvider) != null,
  );
}

@Riverpod(keepAlive: true)
FavoriteRepository favoriteRepository(Ref ref) {
  ref.watch(syncServiceProvider);
  return FavoriteRepositoryImpl(
    ref.watch(favoritesDaoProvider),
    ref.watch(pendingOpsDaoProvider),
    ref.watch(localIdentityStoreProvider),
    syncEnabled: ref.watch(supabaseClientProvider) != null,
  );
}

// ── 동기화 서비스 ────────────────────────────────────────────────────

/// 온라인 전환/큐 변화에 따라 `pending_ops`를 Supabase로 push 한다(§5.3).
/// 미구성 시에는 리스너를 걸지 않고 로컬 전용으로 동작한다.
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  final service = SyncService(
    pendingOps: ref.watch(pendingOpsDaoProvider),
    trackingDao: ref.watch(trackingLogsDaoProvider),
    babiesDao: ref.watch(babiesDaoProvider),
    favoritesDao: ref.watch(favoritesDaoProvider),
    auth: ref.watch(authRepositoryProvider),
    trackingRemote: ref.watch(trackingRemoteDataSourceProvider),
    babyRemote: ref.watch(babyRemoteDataSourceProvider),
    favoriteRemote: ref.watch(favoriteRemoteDataSourceProvider),
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
}
