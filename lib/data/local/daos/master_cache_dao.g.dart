// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'master_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$MasterCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedSymptomsTable get cachedSymptoms => attachedDatabase.cachedSymptoms;
  $CachedSymptomInfosTable get cachedSymptomInfos =>
      attachedDatabase.cachedSymptomInfos;
  $CachedProductsTable get cachedProducts => attachedDatabase.cachedProducts;
  $CacheMetaTable get cacheMeta => attachedDatabase.cacheMeta;
  MasterCacheDaoManager get managers => MasterCacheDaoManager(this);
}

class MasterCacheDaoManager {
  final _$MasterCacheDaoMixin _db;
  MasterCacheDaoManager(this._db);
  $$CachedSymptomsTableTableManager get cachedSymptoms =>
      $$CachedSymptomsTableTableManager(
        _db.attachedDatabase,
        _db.cachedSymptoms,
      );
  $$CachedSymptomInfosTableTableManager get cachedSymptomInfos =>
      $$CachedSymptomInfosTableTableManager(
        _db.attachedDatabase,
        _db.cachedSymptomInfos,
      );
  $$CachedProductsTableTableManager get cachedProducts =>
      $$CachedProductsTableTableManager(
        _db.attachedDatabase,
        _db.cachedProducts,
      );
  $$CacheMetaTableTableManager get cacheMeta =>
      $$CacheMetaTableTableManager(_db.attachedDatabase, _db.cacheMeta);
}
