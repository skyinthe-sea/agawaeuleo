// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracking_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackingLog {

 String get id; String get userId;/// `baby_id`(nullable — 선택된 아기 없이도 기록 가능).
 String? get babyId;/// `type`.
 TrackingType get type;/// `subtype`(nullable — sleep은 null).
 TrackingSubtype? get subtype;/// `amount` — ml, 분 등(nullable).
 double? get amount;/// `note`(nullable).
 String? get note;/// `started_at`.
 DateTime get startedAt;/// `ended_at`(nullable). null = 진행 중 타이머(§11.11).
 DateTime? get endedAt; DateTime get createdAt;
/// Create a copy of TrackingLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackingLogCopyWith<TrackingLog> get copyWith => _$TrackingLogCopyWithImpl<TrackingLog>(this as TrackingLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackingLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.type, type) || other.type == type)&&(identical(other.subtype, subtype) || other.subtype == subtype)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,babyId,type,subtype,amount,note,startedAt,endedAt,createdAt);

@override
String toString() {
  return 'TrackingLog(id: $id, userId: $userId, babyId: $babyId, type: $type, subtype: $subtype, amount: $amount, note: $note, startedAt: $startedAt, endedAt: $endedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TrackingLogCopyWith<$Res>  {
  factory $TrackingLogCopyWith(TrackingLog value, $Res Function(TrackingLog) _then) = _$TrackingLogCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String? babyId, TrackingType type, TrackingSubtype? subtype, double? amount, String? note, DateTime startedAt, DateTime? endedAt, DateTime createdAt
});




}
/// @nodoc
class _$TrackingLogCopyWithImpl<$Res>
    implements $TrackingLogCopyWith<$Res> {
  _$TrackingLogCopyWithImpl(this._self, this._then);

  final TrackingLog _self;
  final $Res Function(TrackingLog) _then;

/// Create a copy of TrackingLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? babyId = freezed,Object? type = null,Object? subtype = freezed,Object? amount = freezed,Object? note = freezed,Object? startedAt = null,Object? endedAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,babyId: freezed == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TrackingType,subtype: freezed == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as TrackingSubtype?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackingLog].
extension TrackingLogPatterns on TrackingLog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackingLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackingLog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackingLog value)  $default,){
final _that = this;
switch (_that) {
case _TrackingLog():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackingLog value)?  $default,){
final _that = this;
switch (_that) {
case _TrackingLog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String? babyId,  TrackingType type,  TrackingSubtype? subtype,  double? amount,  String? note,  DateTime startedAt,  DateTime? endedAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackingLog() when $default != null:
return $default(_that.id,_that.userId,_that.babyId,_that.type,_that.subtype,_that.amount,_that.note,_that.startedAt,_that.endedAt,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String? babyId,  TrackingType type,  TrackingSubtype? subtype,  double? amount,  String? note,  DateTime startedAt,  DateTime? endedAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TrackingLog():
return $default(_that.id,_that.userId,_that.babyId,_that.type,_that.subtype,_that.amount,_that.note,_that.startedAt,_that.endedAt,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String? babyId,  TrackingType type,  TrackingSubtype? subtype,  double? amount,  String? note,  DateTime startedAt,  DateTime? endedAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TrackingLog() when $default != null:
return $default(_that.id,_that.userId,_that.babyId,_that.type,_that.subtype,_that.amount,_that.note,_that.startedAt,_that.endedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _TrackingLog extends TrackingLog {
  const _TrackingLog({required this.id, required this.userId, this.babyId, required this.type, this.subtype, this.amount, this.note, required this.startedAt, this.endedAt, required this.createdAt}): super._();
  

@override final  String id;
@override final  String userId;
/// `baby_id`(nullable — 선택된 아기 없이도 기록 가능).
@override final  String? babyId;
/// `type`.
@override final  TrackingType type;
/// `subtype`(nullable — sleep은 null).
@override final  TrackingSubtype? subtype;
/// `amount` — ml, 분 등(nullable).
@override final  double? amount;
/// `note`(nullable).
@override final  String? note;
/// `started_at`.
@override final  DateTime startedAt;
/// `ended_at`(nullable). null = 진행 중 타이머(§11.11).
@override final  DateTime? endedAt;
@override final  DateTime createdAt;

/// Create a copy of TrackingLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackingLogCopyWith<_TrackingLog> get copyWith => __$TrackingLogCopyWithImpl<_TrackingLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackingLog&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.type, type) || other.type == type)&&(identical(other.subtype, subtype) || other.subtype == subtype)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,babyId,type,subtype,amount,note,startedAt,endedAt,createdAt);

@override
String toString() {
  return 'TrackingLog(id: $id, userId: $userId, babyId: $babyId, type: $type, subtype: $subtype, amount: $amount, note: $note, startedAt: $startedAt, endedAt: $endedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TrackingLogCopyWith<$Res> implements $TrackingLogCopyWith<$Res> {
  factory _$TrackingLogCopyWith(_TrackingLog value, $Res Function(_TrackingLog) _then) = __$TrackingLogCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String? babyId, TrackingType type, TrackingSubtype? subtype, double? amount, String? note, DateTime startedAt, DateTime? endedAt, DateTime createdAt
});




}
/// @nodoc
class __$TrackingLogCopyWithImpl<$Res>
    implements _$TrackingLogCopyWith<$Res> {
  __$TrackingLogCopyWithImpl(this._self, this._then);

  final _TrackingLog _self;
  final $Res Function(_TrackingLog) _then;

/// Create a copy of TrackingLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? babyId = freezed,Object? type = null,Object? subtype = freezed,Object? amount = freezed,Object? note = freezed,Object? startedAt = null,Object? endedAt = freezed,Object? createdAt = null,}) {
  return _then(_TrackingLog(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,babyId: freezed == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TrackingType,subtype: freezed == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as TrackingSubtype?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
