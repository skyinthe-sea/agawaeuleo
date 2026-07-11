// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'symptom.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Symptom {

/// `id` (uuid).
 String get id;/// `slug` — 'colic', 'teething' 등 안정적 식별자.
 String get slug;/// `name` — 표시명. 예: '배앓이'.
 String get name;/// `chosung` — 검색용 초성열. 예: 'ㅂㅇㅇ'. (§11.8)
 String get chosung;/// `aliases` — 동의어. 예: ['가스', '영아산통'].
 List<String> get aliases;/// `tagline` — 홈 카드 한 줄 설명(§11.7 일러스트 카드). 예: '이유 없이
/// 심하게 울 때'. 참고용 톤 유지 — 의학 카피 검수 대상(§13.3).
 String? get tagline;/// `emoji_or_icon` — 아이콘 키(nullable).
 String? get emojiOrIcon;/// `product_keywords` — 제품 검색 키워드(Edge Function 사용). §7.1
 List<String> get productKeywords;/// `order_index` — 홈 그리드 정렬 순서.
 int get orderIndex;/// `is_active`.
 bool get isActive;/// `created_at`.
 DateTime get createdAt;
/// Create a copy of Symptom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SymptomCopyWith<Symptom> get copyWith => _$SymptomCopyWithImpl<Symptom>(this as Symptom, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Symptom&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.chosung, chosung) || other.chosung == chosung)&&const DeepCollectionEquality().equals(other.aliases, aliases)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.emojiOrIcon, emojiOrIcon) || other.emojiOrIcon == emojiOrIcon)&&const DeepCollectionEquality().equals(other.productKeywords, productKeywords)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,name,chosung,const DeepCollectionEquality().hash(aliases),tagline,emojiOrIcon,const DeepCollectionEquality().hash(productKeywords),orderIndex,isActive,createdAt);

@override
String toString() {
  return 'Symptom(id: $id, slug: $slug, name: $name, chosung: $chosung, aliases: $aliases, tagline: $tagline, emojiOrIcon: $emojiOrIcon, productKeywords: $productKeywords, orderIndex: $orderIndex, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SymptomCopyWith<$Res>  {
  factory $SymptomCopyWith(Symptom value, $Res Function(Symptom) _then) = _$SymptomCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String name, String chosung, List<String> aliases, String? tagline, String? emojiOrIcon, List<String> productKeywords, int orderIndex, bool isActive, DateTime createdAt
});




}
/// @nodoc
class _$SymptomCopyWithImpl<$Res>
    implements $SymptomCopyWith<$Res> {
  _$SymptomCopyWithImpl(this._self, this._then);

  final Symptom _self;
  final $Res Function(Symptom) _then;

/// Create a copy of Symptom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? chosung = null,Object? aliases = null,Object? tagline = freezed,Object? emojiOrIcon = freezed,Object? productKeywords = null,Object? orderIndex = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,chosung: null == chosung ? _self.chosung : chosung // ignore: cast_nullable_to_non_nullable
as String,aliases: null == aliases ? _self.aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,emojiOrIcon: freezed == emojiOrIcon ? _self.emojiOrIcon : emojiOrIcon // ignore: cast_nullable_to_non_nullable
as String?,productKeywords: null == productKeywords ? _self.productKeywords : productKeywords // ignore: cast_nullable_to_non_nullable
as List<String>,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Symptom].
extension SymptomPatterns on Symptom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Symptom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Symptom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Symptom value)  $default,){
final _that = this;
switch (_that) {
case _Symptom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Symptom value)?  $default,){
final _that = this;
switch (_that) {
case _Symptom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String chosung,  List<String> aliases,  String? tagline,  String? emojiOrIcon,  List<String> productKeywords,  int orderIndex,  bool isActive,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Symptom() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.chosung,_that.aliases,_that.tagline,_that.emojiOrIcon,_that.productKeywords,_that.orderIndex,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String name,  String chosung,  List<String> aliases,  String? tagline,  String? emojiOrIcon,  List<String> productKeywords,  int orderIndex,  bool isActive,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Symptom():
return $default(_that.id,_that.slug,_that.name,_that.chosung,_that.aliases,_that.tagline,_that.emojiOrIcon,_that.productKeywords,_that.orderIndex,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String name,  String chosung,  List<String> aliases,  String? tagline,  String? emojiOrIcon,  List<String> productKeywords,  int orderIndex,  bool isActive,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Symptom() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.chosung,_that.aliases,_that.tagline,_that.emojiOrIcon,_that.productKeywords,_that.orderIndex,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Symptom implements Symptom {
  const _Symptom({required this.id, required this.slug, required this.name, required this.chosung, final  List<String> aliases = const <String>[], this.tagline, this.emojiOrIcon, final  List<String> productKeywords = const <String>[], this.orderIndex = 0, this.isActive = true, required this.createdAt}): _aliases = aliases,_productKeywords = productKeywords;
  

/// `id` (uuid).
@override final  String id;
/// `slug` — 'colic', 'teething' 등 안정적 식별자.
@override final  String slug;
/// `name` — 표시명. 예: '배앓이'.
@override final  String name;
/// `chosung` — 검색용 초성열. 예: 'ㅂㅇㅇ'. (§11.8)
@override final  String chosung;
/// `aliases` — 동의어. 예: ['가스', '영아산통'].
 final  List<String> _aliases;
/// `aliases` — 동의어. 예: ['가스', '영아산통'].
@override@JsonKey() List<String> get aliases {
  if (_aliases is EqualUnmodifiableListView) return _aliases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aliases);
}

/// `tagline` — 홈 카드 한 줄 설명(§11.7 일러스트 카드). 예: '이유 없이
/// 심하게 울 때'. 참고용 톤 유지 — 의학 카피 검수 대상(§13.3).
@override final  String? tagline;
/// `emoji_or_icon` — 아이콘 키(nullable).
@override final  String? emojiOrIcon;
/// `product_keywords` — 제품 검색 키워드(Edge Function 사용). §7.1
 final  List<String> _productKeywords;
/// `product_keywords` — 제품 검색 키워드(Edge Function 사용). §7.1
@override@JsonKey() List<String> get productKeywords {
  if (_productKeywords is EqualUnmodifiableListView) return _productKeywords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productKeywords);
}

/// `order_index` — 홈 그리드 정렬 순서.
@override@JsonKey() final  int orderIndex;
/// `is_active`.
@override@JsonKey() final  bool isActive;
/// `created_at`.
@override final  DateTime createdAt;

/// Create a copy of Symptom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SymptomCopyWith<_Symptom> get copyWith => __$SymptomCopyWithImpl<_Symptom>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Symptom&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.chosung, chosung) || other.chosung == chosung)&&const DeepCollectionEquality().equals(other._aliases, _aliases)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.emojiOrIcon, emojiOrIcon) || other.emojiOrIcon == emojiOrIcon)&&const DeepCollectionEquality().equals(other._productKeywords, _productKeywords)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,name,chosung,const DeepCollectionEquality().hash(_aliases),tagline,emojiOrIcon,const DeepCollectionEquality().hash(_productKeywords),orderIndex,isActive,createdAt);

@override
String toString() {
  return 'Symptom(id: $id, slug: $slug, name: $name, chosung: $chosung, aliases: $aliases, tagline: $tagline, emojiOrIcon: $emojiOrIcon, productKeywords: $productKeywords, orderIndex: $orderIndex, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SymptomCopyWith<$Res> implements $SymptomCopyWith<$Res> {
  factory _$SymptomCopyWith(_Symptom value, $Res Function(_Symptom) _then) = __$SymptomCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String name, String chosung, List<String> aliases, String? tagline, String? emojiOrIcon, List<String> productKeywords, int orderIndex, bool isActive, DateTime createdAt
});




}
/// @nodoc
class __$SymptomCopyWithImpl<$Res>
    implements _$SymptomCopyWith<$Res> {
  __$SymptomCopyWithImpl(this._self, this._then);

  final _Symptom _self;
  final $Res Function(_Symptom) _then;

/// Create a copy of Symptom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? chosung = null,Object? aliases = null,Object? tagline = freezed,Object? emojiOrIcon = freezed,Object? productKeywords = null,Object? orderIndex = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_Symptom(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,chosung: null == chosung ? _self.chosung : chosung // ignore: cast_nullable_to_non_nullable
as String,aliases: null == aliases ? _self._aliases : aliases // ignore: cast_nullable_to_non_nullable
as List<String>,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,emojiOrIcon: freezed == emojiOrIcon ? _self.emojiOrIcon : emojiOrIcon // ignore: cast_nullable_to_non_nullable
as String?,productKeywords: null == productKeywords ? _self._productKeywords : productKeywords // ignore: cast_nullable_to_non_nullable
as List<String>,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
