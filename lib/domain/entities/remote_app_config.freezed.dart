// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'remote_app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RemoteAppConfig {

/// iOS 최소 허용 버전(semver). 미만이면 강제 업데이트.
 String get minVersionIos;/// Android 최소 허용 버전(semver). 미만이면 강제 업데이트.
 String get minVersionAndroid;/// 점검 모드 플래그. true면 앱 이용 차단 화면 노출.
 bool get maintenance;/// 점검 안내 메시지(nullable).
 String? get maintenanceMessage;
/// Create a copy of RemoteAppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemoteAppConfigCopyWith<RemoteAppConfig> get copyWith => _$RemoteAppConfigCopyWithImpl<RemoteAppConfig>(this as RemoteAppConfig, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RemoteAppConfig&&(identical(other.minVersionIos, minVersionIos) || other.minVersionIos == minVersionIos)&&(identical(other.minVersionAndroid, minVersionAndroid) || other.minVersionAndroid == minVersionAndroid)&&(identical(other.maintenance, maintenance) || other.maintenance == maintenance)&&(identical(other.maintenanceMessage, maintenanceMessage) || other.maintenanceMessage == maintenanceMessage));
}


@override
int get hashCode => Object.hash(runtimeType,minVersionIos,minVersionAndroid,maintenance,maintenanceMessage);

@override
String toString() {
  return 'RemoteAppConfig(minVersionIos: $minVersionIos, minVersionAndroid: $minVersionAndroid, maintenance: $maintenance, maintenanceMessage: $maintenanceMessage)';
}


}

/// @nodoc
abstract mixin class $RemoteAppConfigCopyWith<$Res>  {
  factory $RemoteAppConfigCopyWith(RemoteAppConfig value, $Res Function(RemoteAppConfig) _then) = _$RemoteAppConfigCopyWithImpl;
@useResult
$Res call({
 String minVersionIos, String minVersionAndroid, bool maintenance, String? maintenanceMessage
});




}
/// @nodoc
class _$RemoteAppConfigCopyWithImpl<$Res>
    implements $RemoteAppConfigCopyWith<$Res> {
  _$RemoteAppConfigCopyWithImpl(this._self, this._then);

  final RemoteAppConfig _self;
  final $Res Function(RemoteAppConfig) _then;

/// Create a copy of RemoteAppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minVersionIos = null,Object? minVersionAndroid = null,Object? maintenance = null,Object? maintenanceMessage = freezed,}) {
  return _then(_self.copyWith(
minVersionIos: null == minVersionIos ? _self.minVersionIos : minVersionIos // ignore: cast_nullable_to_non_nullable
as String,minVersionAndroid: null == minVersionAndroid ? _self.minVersionAndroid : minVersionAndroid // ignore: cast_nullable_to_non_nullable
as String,maintenance: null == maintenance ? _self.maintenance : maintenance // ignore: cast_nullable_to_non_nullable
as bool,maintenanceMessage: freezed == maintenanceMessage ? _self.maintenanceMessage : maintenanceMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RemoteAppConfig].
extension RemoteAppConfigPatterns on RemoteAppConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RemoteAppConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RemoteAppConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RemoteAppConfig value)  $default,){
final _that = this;
switch (_that) {
case _RemoteAppConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RemoteAppConfig value)?  $default,){
final _that = this;
switch (_that) {
case _RemoteAppConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String minVersionIos,  String minVersionAndroid,  bool maintenance,  String? maintenanceMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RemoteAppConfig() when $default != null:
return $default(_that.minVersionIos,_that.minVersionAndroid,_that.maintenance,_that.maintenanceMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String minVersionIos,  String minVersionAndroid,  bool maintenance,  String? maintenanceMessage)  $default,) {final _that = this;
switch (_that) {
case _RemoteAppConfig():
return $default(_that.minVersionIos,_that.minVersionAndroid,_that.maintenance,_that.maintenanceMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String minVersionIos,  String minVersionAndroid,  bool maintenance,  String? maintenanceMessage)?  $default,) {final _that = this;
switch (_that) {
case _RemoteAppConfig() when $default != null:
return $default(_that.minVersionIos,_that.minVersionAndroid,_that.maintenance,_that.maintenanceMessage);case _:
  return null;

}
}

}

/// @nodoc


class _RemoteAppConfig extends RemoteAppConfig {
  const _RemoteAppConfig({this.minVersionIos = '0.0.0', this.minVersionAndroid = '0.0.0', this.maintenance = false, this.maintenanceMessage}): super._();
  

/// iOS 최소 허용 버전(semver). 미만이면 강제 업데이트.
@override@JsonKey() final  String minVersionIos;
/// Android 최소 허용 버전(semver). 미만이면 강제 업데이트.
@override@JsonKey() final  String minVersionAndroid;
/// 점검 모드 플래그. true면 앱 이용 차단 화면 노출.
@override@JsonKey() final  bool maintenance;
/// 점검 안내 메시지(nullable).
@override final  String? maintenanceMessage;

/// Create a copy of RemoteAppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoteAppConfigCopyWith<_RemoteAppConfig> get copyWith => __$RemoteAppConfigCopyWithImpl<_RemoteAppConfig>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoteAppConfig&&(identical(other.minVersionIos, minVersionIos) || other.minVersionIos == minVersionIos)&&(identical(other.minVersionAndroid, minVersionAndroid) || other.minVersionAndroid == minVersionAndroid)&&(identical(other.maintenance, maintenance) || other.maintenance == maintenance)&&(identical(other.maintenanceMessage, maintenanceMessage) || other.maintenanceMessage == maintenanceMessage));
}


@override
int get hashCode => Object.hash(runtimeType,minVersionIos,minVersionAndroid,maintenance,maintenanceMessage);

@override
String toString() {
  return 'RemoteAppConfig(minVersionIos: $minVersionIos, minVersionAndroid: $minVersionAndroid, maintenance: $maintenance, maintenanceMessage: $maintenanceMessage)';
}


}

/// @nodoc
abstract mixin class _$RemoteAppConfigCopyWith<$Res> implements $RemoteAppConfigCopyWith<$Res> {
  factory _$RemoteAppConfigCopyWith(_RemoteAppConfig value, $Res Function(_RemoteAppConfig) _then) = __$RemoteAppConfigCopyWithImpl;
@override @useResult
$Res call({
 String minVersionIos, String minVersionAndroid, bool maintenance, String? maintenanceMessage
});




}
/// @nodoc
class __$RemoteAppConfigCopyWithImpl<$Res>
    implements _$RemoteAppConfigCopyWith<$Res> {
  __$RemoteAppConfigCopyWithImpl(this._self, this._then);

  final _RemoteAppConfig _self;
  final $Res Function(_RemoteAppConfig) _then;

/// Create a copy of RemoteAppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minVersionIos = null,Object? minVersionAndroid = null,Object? maintenance = null,Object? maintenanceMessage = freezed,}) {
  return _then(_RemoteAppConfig(
minVersionIos: null == minVersionIos ? _self.minVersionIos : minVersionIos // ignore: cast_nullable_to_non_nullable
as String,minVersionAndroid: null == minVersionAndroid ? _self.minVersionAndroid : minVersionAndroid // ignore: cast_nullable_to_non_nullable
as String,maintenance: null == maintenance ? _self.maintenance : maintenance // ignore: cast_nullable_to_non_nullable
as bool,maintenanceMessage: freezed == maintenanceMessage ? _self.maintenanceMessage : maintenanceMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
