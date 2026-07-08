// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'symptom_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InfoSection {

 String get title; String get body;
/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionCopyWith<InfoSection> get copyWith => _$InfoSectionCopyWithImpl<InfoSection>(this as InfoSection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSection&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,title,body);

@override
String toString() {
  return 'InfoSection(title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class $InfoSectionCopyWith<$Res>  {
  factory $InfoSectionCopyWith(InfoSection value, $Res Function(InfoSection) _then) = _$InfoSectionCopyWithImpl;
@useResult
$Res call({
 String title, String body
});




}
/// @nodoc
class _$InfoSectionCopyWithImpl<$Res>
    implements $InfoSectionCopyWith<$Res> {
  _$InfoSectionCopyWithImpl(this._self, this._then);

  final InfoSection _self;
  final $Res Function(InfoSection) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? body = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InfoSection].
extension InfoSectionPatterns on InfoSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InfoSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InfoSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InfoSection value)  $default,){
final _that = this;
switch (_that) {
case _InfoSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InfoSection value)?  $default,){
final _that = this;
switch (_that) {
case _InfoSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InfoSection() when $default != null:
return $default(_that.title,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String body)  $default,) {final _that = this;
switch (_that) {
case _InfoSection():
return $default(_that.title,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String body)?  $default,) {final _that = this;
switch (_that) {
case _InfoSection() when $default != null:
return $default(_that.title,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class _InfoSection implements InfoSection {
  const _InfoSection({required this.title, required this.body});
  

@override final  String title;
@override final  String body;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InfoSectionCopyWith<_InfoSection> get copyWith => __$InfoSectionCopyWithImpl<_InfoSection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InfoSection&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,title,body);

@override
String toString() {
  return 'InfoSection(title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class _$InfoSectionCopyWith<$Res> implements $InfoSectionCopyWith<$Res> {
  factory _$InfoSectionCopyWith(_InfoSection value, $Res Function(_InfoSection) _then) = __$InfoSectionCopyWithImpl;
@override @useResult
$Res call({
 String title, String body
});




}
/// @nodoc
class __$InfoSectionCopyWithImpl<$Res>
    implements _$InfoSectionCopyWith<$Res> {
  __$InfoSectionCopyWithImpl(this._self, this._then);

  final _InfoSection _self;
  final $Res Function(_InfoSection) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? body = null,}) {
  return _then(_InfoSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$EmergencySign {

/// 신호(증상) 설명.
 String get sign;/// 권장 조치.
 String get action;
/// Create a copy of EmergencySign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmergencySignCopyWith<EmergencySign> get copyWith => _$EmergencySignCopyWithImpl<EmergencySign>(this as EmergencySign, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmergencySign&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,sign,action);

@override
String toString() {
  return 'EmergencySign(sign: $sign, action: $action)';
}


}

/// @nodoc
abstract mixin class $EmergencySignCopyWith<$Res>  {
  factory $EmergencySignCopyWith(EmergencySign value, $Res Function(EmergencySign) _then) = _$EmergencySignCopyWithImpl;
@useResult
$Res call({
 String sign, String action
});




}
/// @nodoc
class _$EmergencySignCopyWithImpl<$Res>
    implements $EmergencySignCopyWith<$Res> {
  _$EmergencySignCopyWithImpl(this._self, this._then);

  final EmergencySign _self;
  final $Res Function(EmergencySign) _then;

/// Create a copy of EmergencySign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sign = null,Object? action = null,}) {
  return _then(_self.copyWith(
sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EmergencySign].
extension EmergencySignPatterns on EmergencySign {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmergencySign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmergencySign() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmergencySign value)  $default,){
final _that = this;
switch (_that) {
case _EmergencySign():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmergencySign value)?  $default,){
final _that = this;
switch (_that) {
case _EmergencySign() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sign,  String action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmergencySign() when $default != null:
return $default(_that.sign,_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sign,  String action)  $default,) {final _that = this;
switch (_that) {
case _EmergencySign():
return $default(_that.sign,_that.action);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sign,  String action)?  $default,) {final _that = this;
switch (_that) {
case _EmergencySign() when $default != null:
return $default(_that.sign,_that.action);case _:
  return null;

}
}

}

/// @nodoc


class _EmergencySign implements EmergencySign {
  const _EmergencySign({required this.sign, required this.action});
  

/// 신호(증상) 설명.
@override final  String sign;
/// 권장 조치.
@override final  String action;

/// Create a copy of EmergencySign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmergencySignCopyWith<_EmergencySign> get copyWith => __$EmergencySignCopyWithImpl<_EmergencySign>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmergencySign&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,sign,action);

@override
String toString() {
  return 'EmergencySign(sign: $sign, action: $action)';
}


}

/// @nodoc
abstract mixin class _$EmergencySignCopyWith<$Res> implements $EmergencySignCopyWith<$Res> {
  factory _$EmergencySignCopyWith(_EmergencySign value, $Res Function(_EmergencySign) _then) = __$EmergencySignCopyWithImpl;
@override @useResult
$Res call({
 String sign, String action
});




}
/// @nodoc
class __$EmergencySignCopyWithImpl<$Res>
    implements _$EmergencySignCopyWith<$Res> {
  __$EmergencySignCopyWithImpl(this._self, this._then);

  final _EmergencySign _self;
  final $Res Function(_EmergencySign) _then;

/// Create a copy of EmergencySign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sign = null,Object? action = null,}) {
  return _then(_EmergencySign(
sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SymptomInfo {

 String get id; String get symptomId;/// `summary` — 2~3문장 요약.
 String get summary;/// `sections` — 섹션형 본문.
 List<InfoSection> get sections;/// `emergency` — 응급신호 배열(없을 수 있음).
 List<EmergencySign> get emergency; DateTime get updatedAt;
/// Create a copy of SymptomInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SymptomInfoCopyWith<SymptomInfo> get copyWith => _$SymptomInfoCopyWithImpl<SymptomInfo>(this as SymptomInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SymptomInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.symptomId, symptomId) || other.symptomId == symptomId)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.emergency, emergency)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,symptomId,summary,const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(emergency),updatedAt);

@override
String toString() {
  return 'SymptomInfo(id: $id, symptomId: $symptomId, summary: $summary, sections: $sections, emergency: $emergency, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SymptomInfoCopyWith<$Res>  {
  factory $SymptomInfoCopyWith(SymptomInfo value, $Res Function(SymptomInfo) _then) = _$SymptomInfoCopyWithImpl;
@useResult
$Res call({
 String id, String symptomId, String summary, List<InfoSection> sections, List<EmergencySign> emergency, DateTime updatedAt
});




}
/// @nodoc
class _$SymptomInfoCopyWithImpl<$Res>
    implements $SymptomInfoCopyWith<$Res> {
  _$SymptomInfoCopyWithImpl(this._self, this._then);

  final SymptomInfo _self;
  final $Res Function(SymptomInfo) _then;

/// Create a copy of SymptomInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? symptomId = null,Object? summary = null,Object? sections = null,Object? emergency = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symptomId: null == symptomId ? _self.symptomId : symptomId // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<InfoSection>,emergency: null == emergency ? _self.emergency : emergency // ignore: cast_nullable_to_non_nullable
as List<EmergencySign>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SymptomInfo].
extension SymptomInfoPatterns on SymptomInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SymptomInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SymptomInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SymptomInfo value)  $default,){
final _that = this;
switch (_that) {
case _SymptomInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SymptomInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SymptomInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String symptomId,  String summary,  List<InfoSection> sections,  List<EmergencySign> emergency,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SymptomInfo() when $default != null:
return $default(_that.id,_that.symptomId,_that.summary,_that.sections,_that.emergency,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String symptomId,  String summary,  List<InfoSection> sections,  List<EmergencySign> emergency,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SymptomInfo():
return $default(_that.id,_that.symptomId,_that.summary,_that.sections,_that.emergency,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String symptomId,  String summary,  List<InfoSection> sections,  List<EmergencySign> emergency,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SymptomInfo() when $default != null:
return $default(_that.id,_that.symptomId,_that.summary,_that.sections,_that.emergency,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SymptomInfo extends SymptomInfo {
  const _SymptomInfo({required this.id, required this.symptomId, required this.summary, final  List<InfoSection> sections = const <InfoSection>[], final  List<EmergencySign> emergency = const <EmergencySign>[], required this.updatedAt}): _sections = sections,_emergency = emergency,super._();
  

@override final  String id;
@override final  String symptomId;
/// `summary` — 2~3문장 요약.
@override final  String summary;
/// `sections` — 섹션형 본문.
 final  List<InfoSection> _sections;
/// `sections` — 섹션형 본문.
@override@JsonKey() List<InfoSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// `emergency` — 응급신호 배열(없을 수 있음).
 final  List<EmergencySign> _emergency;
/// `emergency` — 응급신호 배열(없을 수 있음).
@override@JsonKey() List<EmergencySign> get emergency {
  if (_emergency is EqualUnmodifiableListView) return _emergency;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_emergency);
}

@override final  DateTime updatedAt;

/// Create a copy of SymptomInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SymptomInfoCopyWith<_SymptomInfo> get copyWith => __$SymptomInfoCopyWithImpl<_SymptomInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SymptomInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.symptomId, symptomId) || other.symptomId == symptomId)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._emergency, _emergency)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,symptomId,summary,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_emergency),updatedAt);

@override
String toString() {
  return 'SymptomInfo(id: $id, symptomId: $symptomId, summary: $summary, sections: $sections, emergency: $emergency, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SymptomInfoCopyWith<$Res> implements $SymptomInfoCopyWith<$Res> {
  factory _$SymptomInfoCopyWith(_SymptomInfo value, $Res Function(_SymptomInfo) _then) = __$SymptomInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String symptomId, String summary, List<InfoSection> sections, List<EmergencySign> emergency, DateTime updatedAt
});




}
/// @nodoc
class __$SymptomInfoCopyWithImpl<$Res>
    implements _$SymptomInfoCopyWith<$Res> {
  __$SymptomInfoCopyWithImpl(this._self, this._then);

  final _SymptomInfo _self;
  final $Res Function(_SymptomInfo) _then;

/// Create a copy of SymptomInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? symptomId = null,Object? summary = null,Object? sections = null,Object? emergency = null,Object? updatedAt = null,}) {
  return _then(_SymptomInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symptomId: null == symptomId ? _self.symptomId : symptomId // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<InfoSection>,emergency: null == emergency ? _self._emergency : emergency // ignore: cast_nullable_to_non_nullable
as List<EmergencySign>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
