// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'babies_dao.dart';

// ignore_for_file: type=lint
mixin _$BabiesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BabiesTable get babies => attachedDatabase.babies;
  BabiesDaoManager get managers => BabiesDaoManager(this);
}

class BabiesDaoManager {
  final _$BabiesDaoMixin _db;
  BabiesDaoManager(this._db);
  $$BabiesTableTableManager get babies =>
      $$BabiesTableTableManager(_db.attachedDatabase, _db.babies);
}
