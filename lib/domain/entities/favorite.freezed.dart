// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Favorite {

 String get id; String get userId;/// `target_type`.
 FavoriteTargetType get targetType;/// `target_id` — 대상 증상/제품의 uuid.
 String get targetId; DateTime get createdAt;
/// Create a copy of Favorite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteCopyWith<Favorite> get copyWith => _$FavoriteCopyWithImpl<Favorite>(this as Favorite, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Favorite&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,targetType,targetId,createdAt);

@override
String toString() {
  return 'Favorite(id: $id, userId: $userId, targetType: $targetType, targetId: $targetId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $FavoriteCopyWith<$Res>  {
  factory $FavoriteCopyWith(Favorite value, $Res Function(Favorite) _then) = _$FavoriteCopyWithImpl;
@useResult
$Res call({
 String id, String userId, FavoriteTargetType targetType, String targetId, DateTime createdAt
});




}
/// @nodoc
class _$FavoriteCopyWithImpl<$Res>
    implements $FavoriteCopyWith<$Res> {
  _$FavoriteCopyWithImpl(this._self, this._then);

  final Favorite _self;
  final $Res Function(Favorite) _then;

/// Create a copy of Favorite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? targetType = null,Object? targetId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as FavoriteTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Favorite].
extension FavoritePatterns on Favorite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Favorite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Favorite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Favorite value)  $default,){
final _that = this;
switch (_that) {
case _Favorite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Favorite value)?  $default,){
final _that = this;
switch (_that) {
case _Favorite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  FavoriteTargetType targetType,  String targetId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Favorite() when $default != null:
return $default(_that.id,_that.userId,_that.targetType,_that.targetId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  FavoriteTargetType targetType,  String targetId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Favorite():
return $default(_that.id,_that.userId,_that.targetType,_that.targetId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  FavoriteTargetType targetType,  String targetId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Favorite() when $default != null:
return $default(_that.id,_that.userId,_that.targetType,_that.targetId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Favorite implements Favorite {
  const _Favorite({required this.id, required this.userId, required this.targetType, required this.targetId, required this.createdAt});
  

@override final  String id;
@override final  String userId;
/// `target_type`.
@override final  FavoriteTargetType targetType;
/// `target_id` — 대상 증상/제품의 uuid.
@override final  String targetId;
@override final  DateTime createdAt;

/// Create a copy of Favorite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteCopyWith<_Favorite> get copyWith => __$FavoriteCopyWithImpl<_Favorite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Favorite&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,userId,targetType,targetId,createdAt);

@override
String toString() {
  return 'Favorite(id: $id, userId: $userId, targetType: $targetType, targetId: $targetId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$FavoriteCopyWith<$Res> implements $FavoriteCopyWith<$Res> {
  factory _$FavoriteCopyWith(_Favorite value, $Res Function(_Favorite) _then) = __$FavoriteCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, FavoriteTargetType targetType, String targetId, DateTime createdAt
});




}
/// @nodoc
class __$FavoriteCopyWithImpl<$Res>
    implements _$FavoriteCopyWith<$Res> {
  __$FavoriteCopyWithImpl(this._self, this._then);

  final _Favorite _self;
  final $Res Function(_Favorite) _then;

/// Create a copy of Favorite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? targetType = null,Object? targetId = null,Object? createdAt = null,}) {
  return _then(_Favorite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,targetType: null == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as FavoriteTargetType,targetId: null == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
