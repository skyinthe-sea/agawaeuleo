import 'package:agawaeuleo/data/local/daos/babies_dao.dart';
import 'package:agawaeuleo/data/local/daos/favorites_dao.dart';
import 'package:agawaeuleo/data/local/daos/master_cache_dao.dart';
import 'package:agawaeuleo/data/local/daos/pending_ops_dao.dart';
import 'package:agawaeuleo/data/local/daos/recent_searches_dao.dart';
import 'package:agawaeuleo/data/local/daos/tracking_logs_dao.dart';
import 'package:agawaeuleo/data/local/tables/babies_table.dart';
import 'package:agawaeuleo/data/local/tables/cache_meta_table.dart';
import 'package:agawaeuleo/data/local/tables/cached_products_table.dart';
import 'package:agawaeuleo/data/local/tables/cached_symptom_infos_table.dart';
import 'package:agawaeuleo/data/local/tables/cached_symptoms_table.dart';
import 'package:agawaeuleo/data/local/tables/favorites_table.dart';
import 'package:agawaeuleo/data/local/tables/pending_ops_table.dart';
import 'package:agawaeuleo/data/local/tables/recent_searches_table.dart';
import 'package:agawaeuleo/data/local/tables/tracking_logs_table.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// 로컬 우선 저장소의 Drift 데이터베이스 (§5.3).
///
/// 개인기록(기록/아기/즐겨찾기)과 UX 로컬 상태(최근 검색어), 그리고 Supabase
/// 동기화 큐(`pending_ops`)를 담는다. Supabase에 직접 접근하지 않으며,
/// 미구성/오프라인에서도 완전히 동작한다.
@DriftDatabase(
  tables: [
    TrackingLogs,
    Babies,
    Favorites,
    RecentSearches,
    PendingOps,
    // 마스터 데이터 오프라인 캐시(§5.3) — 읽기 전용 캐시, MasterDataCacheService가 채운다.
    CachedSymptoms,
    CachedSymptomInfos,
    CachedProducts,
    CacheMeta,
  ],
  daos: [
    TrackingLogsDao,
    BabiesDao,
    FavoritesDao,
    RecentSearchesDao,
    PendingOpsDao,
    MasterCacheDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// 앱 실행용 — 네이티브 문서 디렉터리의 `agawaeuleo.sqlite` 파일 사용.
  AppDatabase() : super(driftDatabase(name: _dbName));

  /// 테스트용 — 임의의 [QueryExecutor] 주입.
  AppDatabase.forExecutor(super.executor);

  /// 테스트용 in-memory DB(파일 없이 휘발성).
  factory AppDatabase.inMemory() =>
      AppDatabase.forExecutor(NativeDatabase.memory());

  static const String _dbName = 'agawaeuleo';

  // v2: 마스터 데이터 오프라인 캐시 테이블 추가(§5.3 캐싱 기능).
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 개인기록 테이블은 보존하고 캐시 테이블만 신규 생성. 캐시는 비어 있어도
        // MasterDataCacheService가 다음 부팅 때 서버 매니페스트로 다시 채운다.
        await m.createTable(cachedSymptoms);
        await m.createTable(cachedSymptomInfos);
        await m.createTable(cachedProducts);
        await m.createTable(cacheMeta);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
