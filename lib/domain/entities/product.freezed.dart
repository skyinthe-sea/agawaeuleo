// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Product {

 String get id; String get symptomId;/// `coupang_pid` — 쿠팡 상품 식별자.
 String get coupangPid; String get title;/// `image_url`(nullable).
 String? get imageUrl;/// `price`(원, nullable).
 int? get price;/// `rating`(numeric, nullable).
 double? get rating;/// `deeplink` — 내 코드 포함 파트너스 링크.
 String get deeplink;/// `rank_index` — 증상 내 정렬 순서.
 int get rankIndex;/// `is_active`.
 bool get isActive;/// `fetched_at` — Edge Function upsert 시각.
 DateTime get fetchedAt;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.symptomId, symptomId) || other.symptomId == symptomId)&&(identical(other.coupangPid, coupangPid) || other.coupangPid == coupangPid)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.price, price) || other.price == price)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.deeplink, deeplink) || other.deeplink == deeplink)&&(identical(other.rankIndex, rankIndex) || other.rankIndex == rankIndex)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,symptomId,coupangPid,title,imageUrl,price,rating,deeplink,rankIndex,isActive,fetchedAt);

@override
String toString() {
  return 'Product(id: $id, symptomId: $symptomId, coupangPid: $coupangPid, title: $title, imageUrl: $imageUrl, price: $price, rating: $rating, deeplink: $deeplink, rankIndex: $rankIndex, isActive: $isActive, fetchedAt: $fetchedAt)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String symptomId, String coupangPid, String title, String? imageUrl, int? price, double? rating, String deeplink, int rankIndex, bool isActive, DateTime fetchedAt
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? symptomId = null,Object? coupangPid = null,Object? title = null,Object? imageUrl = freezed,Object? price = freezed,Object? rating = freezed,Object? deeplink = null,Object? rankIndex = null,Object? isActive = null,Object? fetchedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symptomId: null == symptomId ? _self.symptomId : symptomId // ignore: cast_nullable_to_non_nullable
as String,coupangPid: null == coupangPid ? _self.coupangPid : coupangPid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,deeplink: null == deeplink ? _self.deeplink : deeplink // ignore: cast_nullable_to_non_nullable
as String,rankIndex: null == rankIndex ? _self.rankIndex : rankIndex // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String symptomId,  String coupangPid,  String title,  String? imageUrl,  int? price,  double? rating,  String deeplink,  int rankIndex,  bool isActive,  DateTime fetchedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.symptomId,_that.coupangPid,_that.title,_that.imageUrl,_that.price,_that.rating,_that.deeplink,_that.rankIndex,_that.isActive,_that.fetchedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String symptomId,  String coupangPid,  String title,  String? imageUrl,  int? price,  double? rating,  String deeplink,  int rankIndex,  bool isActive,  DateTime fetchedAt)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.symptomId,_that.coupangPid,_that.title,_that.imageUrl,_that.price,_that.rating,_that.deeplink,_that.rankIndex,_that.isActive,_that.fetchedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String symptomId,  String coupangPid,  String title,  String? imageUrl,  int? price,  double? rating,  String deeplink,  int rankIndex,  bool isActive,  DateTime fetchedAt)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.symptomId,_that.coupangPid,_that.title,_that.imageUrl,_that.price,_that.rating,_that.deeplink,_that.rankIndex,_that.isActive,_that.fetchedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Product implements Product {
  const _Product({required this.id, required this.symptomId, required this.coupangPid, required this.title, this.imageUrl, this.price, this.rating, required this.deeplink, this.rankIndex = 0, this.isActive = true, required this.fetchedAt});
  

@override final  String id;
@override final  String symptomId;
/// `coupang_pid` — 쿠팡 상품 식별자.
@override final  String coupangPid;
@override final  String title;
/// `image_url`(nullable).
@override final  String? imageUrl;
/// `price`(원, nullable).
@override final  int? price;
/// `rating`(numeric, nullable).
@override final  double? rating;
/// `deeplink` — 내 코드 포함 파트너스 링크.
@override final  String deeplink;
/// `rank_index` — 증상 내 정렬 순서.
@override@JsonKey() final  int rankIndex;
/// `is_active`.
@override@JsonKey() final  bool isActive;
/// `fetched_at` — Edge Function upsert 시각.
@override final  DateTime fetchedAt;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.symptomId, symptomId) || other.symptomId == symptomId)&&(identical(other.coupangPid, coupangPid) || other.coupangPid == coupangPid)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.price, price) || other.price == price)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.deeplink, deeplink) || other.deeplink == deeplink)&&(identical(other.rankIndex, rankIndex) || other.rankIndex == rankIndex)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,symptomId,coupangPid,title,imageUrl,price,rating,deeplink,rankIndex,isActive,fetchedAt);

@override
String toString() {
  return 'Product(id: $id, symptomId: $symptomId, coupangPid: $coupangPid, title: $title, imageUrl: $imageUrl, price: $price, rating: $rating, deeplink: $deeplink, rankIndex: $rankIndex, isActive: $isActive, fetchedAt: $fetchedAt)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String symptomId, String coupangPid, String title, String? imageUrl, int? price, double? rating, String deeplink, int rankIndex, bool isActive, DateTime fetchedAt
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? symptomId = null,Object? coupangPid = null,Object? title = null,Object? imageUrl = freezed,Object? price = freezed,Object? rating = freezed,Object? deeplink = null,Object? rankIndex = null,Object? isActive = null,Object? fetchedAt = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symptomId: null == symptomId ? _self.symptomId : symptomId // ignore: cast_nullable_to_non_nullable
as String,coupangPid: null == coupangPid ? _self.coupangPid : coupangPid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,deeplink: null == deeplink ? _self.deeplink : deeplink // ignore: cast_nullable_to_non_nullable
as String,rankIndex: null == rankIndex ? _self.rankIndex : rankIndex // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
