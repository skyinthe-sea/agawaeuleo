// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$TrackingLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrackingLogsTable get trackingLogs => attachedDatabase.trackingLogs;
  TrackingLogsDaoManager get managers => TrackingLogsDaoManager(this);
}

class TrackingLogsDaoManager {
  final _$TrackingLogsDaoMixin _db;
  TrackingLogsDaoManager(this._db);
  $$TrackingLogsTableTableManager get trackingLogs =>
      $$TrackingLogsTableTableManager(_db.attachedDatabase, _db.trackingLogs);
}
