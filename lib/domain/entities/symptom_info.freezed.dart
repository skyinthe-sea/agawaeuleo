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

 String get title;
/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionCopyWith<InfoSection> get copyWith => _$InfoSectionCopyWithImpl<InfoSection>(this as InfoSection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSection&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,title);

@override
String toString() {
  return 'InfoSection(title: $title)';
}


}

/// @nodoc
abstract mixin class $InfoSectionCopyWith<$Res>  {
  factory $InfoSectionCopyWith(InfoSection value, $Res Function(InfoSection) _then) = _$InfoSectionCopyWithImpl;
@useResult
$Res call({
 String title
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
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InfoSectionText value)?  text,TResult Function( InfoSectionSteps value)?  steps,TResult Function( InfoSectionChecklist value)?  checklist,TResult Function( InfoSectionTable value)?  table,TResult Function( InfoSectionQa value)?  qa,TResult Function( InfoSectionTips value)?  tips,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InfoSectionText() when text != null:
return text(_that);case InfoSectionSteps() when steps != null:
return steps(_that);case InfoSectionChecklist() when checklist != null:
return checklist(_that);case InfoSectionTable() when table != null:
return table(_that);case InfoSectionQa() when qa != null:
return qa(_that);case InfoSectionTips() when tips != null:
return tips(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InfoSectionText value)  text,required TResult Function( InfoSectionSteps value)  steps,required TResult Function( InfoSectionChecklist value)  checklist,required TResult Function( InfoSectionTable value)  table,required TResult Function( InfoSectionQa value)  qa,required TResult Function( InfoSectionTips value)  tips,}){
final _that = this;
switch (_that) {
case InfoSectionText():
return text(_that);case InfoSectionSteps():
return steps(_that);case InfoSectionChecklist():
return checklist(_that);case InfoSectionTable():
return table(_that);case InfoSectionQa():
return qa(_that);case InfoSectionTips():
return tips(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InfoSectionText value)?  text,TResult? Function( InfoSectionSteps value)?  steps,TResult? Function( InfoSectionChecklist value)?  checklist,TResult? Function( InfoSectionTable value)?  table,TResult? Function( InfoSectionQa value)?  qa,TResult? Function( InfoSectionTips value)?  tips,}){
final _that = this;
switch (_that) {
case InfoSectionText() when text != null:
return text(_that);case InfoSectionSteps() when steps != null:
return steps(_that);case InfoSectionChecklist() when checklist != null:
return checklist(_that);case InfoSectionTable() when table != null:
return table(_that);case InfoSectionQa() when qa != null:
return qa(_that);case InfoSectionTips() when tips != null:
return tips(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String title,  String body)?  text,TResult Function( String title,  List<String> items,  String? intro)?  steps,TResult Function( String title,  List<String> items,  String? intro)?  checklist,TResult Function( String title,  List<String> columns,  List<List<String>> rows,  String? caption)?  table,TResult Function( String title,  List<QaItem> items)?  qa,TResult Function( String title,  List<String> items)?  tips,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InfoSectionText() when text != null:
return text(_that.title,_that.body);case InfoSectionSteps() when steps != null:
return steps(_that.title,_that.items,_that.intro);case InfoSectionChecklist() when checklist != null:
return checklist(_that.title,_that.items,_that.intro);case InfoSectionTable() when table != null:
return table(_that.title,_that.columns,_that.rows,_that.caption);case InfoSectionQa() when qa != null:
return qa(_that.title,_that.items);case InfoSectionTips() when tips != null:
return tips(_that.title,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String title,  String body)  text,required TResult Function( String title,  List<String> items,  String? intro)  steps,required TResult Function( String title,  List<String> items,  String? intro)  checklist,required TResult Function( String title,  List<String> columns,  List<List<String>> rows,  String? caption)  table,required TResult Function( String title,  List<QaItem> items)  qa,required TResult Function( String title,  List<String> items)  tips,}) {final _that = this;
switch (_that) {
case InfoSectionText():
return text(_that.title,_that.body);case InfoSectionSteps():
return steps(_that.title,_that.items,_that.intro);case InfoSectionChecklist():
return checklist(_that.title,_that.items,_that.intro);case InfoSectionTable():
return table(_that.title,_that.columns,_that.rows,_that.caption);case InfoSectionQa():
return qa(_that.title,_that.items);case InfoSectionTips():
return tips(_that.title,_that.items);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String title,  String body)?  text,TResult? Function( String title,  List<String> items,  String? intro)?  steps,TResult? Function( String title,  List<String> items,  String? intro)?  checklist,TResult? Function( String title,  List<String> columns,  List<List<String>> rows,  String? caption)?  table,TResult? Function( String title,  List<QaItem> items)?  qa,TResult? Function( String title,  List<String> items)?  tips,}) {final _that = this;
switch (_that) {
case InfoSectionText() when text != null:
return text(_that.title,_that.body);case InfoSectionSteps() when steps != null:
return steps(_that.title,_that.items,_that.intro);case InfoSectionChecklist() when checklist != null:
return checklist(_that.title,_that.items,_that.intro);case InfoSectionTable() when table != null:
return table(_that.title,_that.columns,_that.rows,_that.caption);case InfoSectionQa() when qa != null:
return qa(_that.title,_that.items);case InfoSectionTips() when tips != null:
return tips(_that.title,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class InfoSectionText implements InfoSection {
  const InfoSectionText({required this.title, required this.body});
  

@override final  String title;
 final  String body;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionTextCopyWith<InfoSectionText> get copyWith => _$InfoSectionTextCopyWithImpl<InfoSectionText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSectionText&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,title,body);

@override
String toString() {
  return 'InfoSection.text(title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class $InfoSectionTextCopyWith<$Res> implements $InfoSectionCopyWith<$Res> {
  factory $InfoSectionTextCopyWith(InfoSectionText value, $Res Function(InfoSectionText) _then) = _$InfoSectionTextCopyWithImpl;
@override @useResult
$Res call({
 String title, String body
});




}
/// @nodoc
class _$InfoSectionTextCopyWithImpl<$Res>
    implements $InfoSectionTextCopyWith<$Res> {
  _$InfoSectionTextCopyWithImpl(this._self, this._then);

  final InfoSectionText _self;
  final $Res Function(InfoSectionText) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? body = null,}) {
  return _then(InfoSectionText(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InfoSectionSteps implements InfoSection {
  const InfoSectionSteps({required this.title, required final  List<String> items, this.intro}): _items = items;
  

@override final  String title;
 final  List<String> _items;
 List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  String? intro;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionStepsCopyWith<InfoSectionSteps> get copyWith => _$InfoSectionStepsCopyWithImpl<InfoSectionSteps>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSectionSteps&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.intro, intro) || other.intro == intro));
}


@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_items),intro);

@override
String toString() {
  return 'InfoSection.steps(title: $title, items: $items, intro: $intro)';
}


}

/// @nodoc
abstract mixin class $InfoSectionStepsCopyWith<$Res> implements $InfoSectionCopyWith<$Res> {
  factory $InfoSectionStepsCopyWith(InfoSectionSteps value, $Res Function(InfoSectionSteps) _then) = _$InfoSectionStepsCopyWithImpl;
@override @useResult
$Res call({
 String title, List<String> items, String? intro
});




}
/// @nodoc
class _$InfoSectionStepsCopyWithImpl<$Res>
    implements $InfoSectionStepsCopyWith<$Res> {
  _$InfoSectionStepsCopyWithImpl(this._self, this._then);

  final InfoSectionSteps _self;
  final $Res Function(InfoSectionSteps) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? items = null,Object? intro = freezed,}) {
  return _then(InfoSectionSteps(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,intro: freezed == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class InfoSectionChecklist implements InfoSection {
  const InfoSectionChecklist({required this.title, required final  List<String> items, this.intro}): _items = items;
  

@override final  String title;
 final  List<String> _items;
 List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  String? intro;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionChecklistCopyWith<InfoSectionChecklist> get copyWith => _$InfoSectionChecklistCopyWithImpl<InfoSectionChecklist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSectionChecklist&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.intro, intro) || other.intro == intro));
}


@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_items),intro);

@override
String toString() {
  return 'InfoSection.checklist(title: $title, items: $items, intro: $intro)';
}


}

/// @nodoc
abstract mixin class $InfoSectionChecklistCopyWith<$Res> implements $InfoSectionCopyWith<$Res> {
  factory $InfoSectionChecklistCopyWith(InfoSectionChecklist value, $Res Function(InfoSectionChecklist) _then) = _$InfoSectionChecklistCopyWithImpl;
@override @useResult
$Res call({
 String title, List<String> items, String? intro
});




}
/// @nodoc
class _$InfoSectionChecklistCopyWithImpl<$Res>
    implements $InfoSectionChecklistCopyWith<$Res> {
  _$InfoSectionChecklistCopyWithImpl(this._self, this._then);

  final InfoSectionChecklist _self;
  final $Res Function(InfoSectionChecklist) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? items = null,Object? intro = freezed,}) {
  return _then(InfoSectionChecklist(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,intro: freezed == intro ? _self.intro : intro // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class InfoSectionTable implements InfoSection {
  const InfoSectionTable({required this.title, required final  List<String> columns, required final  List<List<String>> rows, this.caption}): _columns = columns,_rows = rows;
  

@override final  String title;
 final  List<String> _columns;
 List<String> get columns {
  if (_columns is EqualUnmodifiableListView) return _columns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_columns);
}

 final  List<List<String>> _rows;
 List<List<String>> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  String? caption;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionTableCopyWith<InfoSectionTable> get copyWith => _$InfoSectionTableCopyWithImpl<InfoSectionTable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSectionTable&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._columns, _columns)&&const DeepCollectionEquality().equals(other._rows, _rows)&&(identical(other.caption, caption) || other.caption == caption));
}


@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_columns),const DeepCollectionEquality().hash(_rows),caption);

@override
String toString() {
  return 'InfoSection.table(title: $title, columns: $columns, rows: $rows, caption: $caption)';
}


}

/// @nodoc
abstract mixin class $InfoSectionTableCopyWith<$Res> implements $InfoSectionCopyWith<$Res> {
  factory $InfoSectionTableCopyWith(InfoSectionTable value, $Res Function(InfoSectionTable) _then) = _$InfoSectionTableCopyWithImpl;
@override @useResult
$Res call({
 String title, List<String> columns, List<List<String>> rows, String? caption
});




}
/// @nodoc
class _$InfoSectionTableCopyWithImpl<$Res>
    implements $InfoSectionTableCopyWith<$Res> {
  _$InfoSectionTableCopyWithImpl(this._self, this._then);

  final InfoSectionTable _self;
  final $Res Function(InfoSectionTable) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? columns = null,Object? rows = null,Object? caption = freezed,}) {
  return _then(InfoSectionTable(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,columns: null == columns ? _self._columns : columns // ignore: cast_nullable_to_non_nullable
as List<String>,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<List<String>>,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class InfoSectionQa implements InfoSection {
  const InfoSectionQa({required this.title, required final  List<QaItem> items}): _items = items;
  

@override final  String title;
 final  List<QaItem> _items;
 List<QaItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionQaCopyWith<InfoSectionQa> get copyWith => _$InfoSectionQaCopyWithImpl<InfoSectionQa>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSectionQa&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'InfoSection.qa(title: $title, items: $items)';
}


}

/// @nodoc
abstract mixin class $InfoSectionQaCopyWith<$Res> implements $InfoSectionCopyWith<$Res> {
  factory $InfoSectionQaCopyWith(InfoSectionQa value, $Res Function(InfoSectionQa) _then) = _$InfoSectionQaCopyWithImpl;
@override @useResult
$Res call({
 String title, List<QaItem> items
});




}
/// @nodoc
class _$InfoSectionQaCopyWithImpl<$Res>
    implements $InfoSectionQaCopyWith<$Res> {
  _$InfoSectionQaCopyWithImpl(this._self, this._then);

  final InfoSectionQa _self;
  final $Res Function(InfoSectionQa) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? items = null,}) {
  return _then(InfoSectionQa(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<QaItem>,
  ));
}


}

/// @nodoc


class InfoSectionTips implements InfoSection {
  const InfoSectionTips({required this.title, required final  List<String> items}): _items = items;
  

@override final  String title;
 final  List<String> _items;
 List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSectionTipsCopyWith<InfoSectionTips> get copyWith => _$InfoSectionTipsCopyWithImpl<InfoSectionTips>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSectionTips&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'InfoSection.tips(title: $title, items: $items)';
}


}

/// @nodoc
abstract mixin class $InfoSectionTipsCopyWith<$Res> implements $InfoSectionCopyWith<$Res> {
  factory $InfoSectionTipsCopyWith(InfoSectionTips value, $Res Function(InfoSectionTips) _then) = _$InfoSectionTipsCopyWithImpl;
@override @useResult
$Res call({
 String title, List<String> items
});




}
/// @nodoc
class _$InfoSectionTipsCopyWithImpl<$Res>
    implements $InfoSectionTipsCopyWith<$Res> {
  _$InfoSectionTipsCopyWithImpl(this._self, this._then);

  final InfoSectionTips _self;
  final $Res Function(InfoSectionTips) _then;

/// Create a copy of InfoSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? items = null,}) {
  return _then(InfoSectionTips(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$QaItem {

 String get q; String get a;
/// Create a copy of QaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QaItemCopyWith<QaItem> get copyWith => _$QaItemCopyWithImpl<QaItem>(this as QaItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QaItem&&(identical(other.q, q) || other.q == q)&&(identical(other.a, a) || other.a == a));
}


@override
int get hashCode => Object.hash(runtimeType,q,a);

@override
String toString() {
  return 'QaItem(q: $q, a: $a)';
}


}

/// @nodoc
abstract mixin class $QaItemCopyWith<$Res>  {
  factory $QaItemCopyWith(QaItem value, $Res Function(QaItem) _then) = _$QaItemCopyWithImpl;
@useResult
$Res call({
 String q, String a
});




}
/// @nodoc
class _$QaItemCopyWithImpl<$Res>
    implements $QaItemCopyWith<$Res> {
  _$QaItemCopyWithImpl(this._self, this._then);

  final QaItem _self;
  final $Res Function(QaItem) _then;

/// Create a copy of QaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? q = null,Object? a = null,}) {
  return _then(_self.copyWith(
q: null == q ? _self.q : q // ignore: cast_nullable_to_non_nullable
as String,a: null == a ? _self.a : a // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QaItem].
extension QaItemPatterns on QaItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QaItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QaItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QaItem value)  $default,){
final _that = this;
switch (_that) {
case _QaItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QaItem value)?  $default,){
final _that = this;
switch (_that) {
case _QaItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String q,  String a)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QaItem() when $default != null:
return $default(_that.q,_that.a);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String q,  String a)  $default,) {final _that = this;
switch (_that) {
case _QaItem():
return $default(_that.q,_that.a);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String q,  String a)?  $default,) {final _that = this;
switch (_that) {
case _QaItem() when $default != null:
return $default(_that.q,_that.a);case _:
  return null;

}
}

}

/// @nodoc


class _QaItem implements QaItem {
  const _QaItem({required this.q, required this.a});
  

@override final  String q;
@override final  String a;

/// Create a copy of QaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QaItemCopyWith<_QaItem> get copyWith => __$QaItemCopyWithImpl<_QaItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QaItem&&(identical(other.q, q) || other.q == q)&&(identical(other.a, a) || other.a == a));
}


@override
int get hashCode => Object.hash(runtimeType,q,a);

@override
String toString() {
  return 'QaItem(q: $q, a: $a)';
}


}

/// @nodoc
abstract mixin class _$QaItemCopyWith<$Res> implements $QaItemCopyWith<$Res> {
  factory _$QaItemCopyWith(_QaItem value, $Res Function(_QaItem) _then) = __$QaItemCopyWithImpl;
@override @useResult
$Res call({
 String q, String a
});




}
/// @nodoc
class __$QaItemCopyWithImpl<$Res>
    implements _$QaItemCopyWith<$Res> {
  __$QaItemCopyWithImpl(this._self, this._then);

  final _QaItem _self;
  final $Res Function(_QaItem) _then;

/// Create a copy of QaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? q = null,Object? a = null,}) {
  return _then(_QaItem(
q: null == q ? _self.q : q // ignore: cast_nullable_to_non_nullable
as String,a: null == a ? _self.a : a // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$InfoSource {

/// 한국어 표시명(기관·문서명). 예: '질병관리청 예방접종도우미'.
 String get label;/// 발행 기관 축약(선택). 예: 'AAP', 'WHO'.
 String? get org;/// 원문 URL(선택, 검증된 것만 — 앱은 노출하지 않는다).
 String? get url;
/// Create a copy of InfoSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InfoSourceCopyWith<InfoSource> get copyWith => _$InfoSourceCopyWithImpl<InfoSource>(this as InfoSource, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InfoSource&&(identical(other.label, label) || other.label == label)&&(identical(other.org, org) || other.org == org)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,label,org,url);

@override
String toString() {
  return 'InfoSource(label: $label, org: $org, url: $url)';
}


}

/// @nodoc
abstract mixin class $InfoSourceCopyWith<$Res>  {
  factory $InfoSourceCopyWith(InfoSource value, $Res Function(InfoSource) _then) = _$InfoSourceCopyWithImpl;
@useResult
$Res call({
 String label, String? org, String? url
});




}
/// @nodoc
class _$InfoSourceCopyWithImpl<$Res>
    implements $InfoSourceCopyWith<$Res> {
  _$InfoSourceCopyWithImpl(this._self, this._then);

  final InfoSource _self;
  final $Res Function(InfoSource) _then;

/// Create a copy of InfoSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? org = freezed,Object? url = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,org: freezed == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InfoSource].
extension InfoSourcePatterns on InfoSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InfoSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InfoSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InfoSource value)  $default,){
final _that = this;
switch (_that) {
case _InfoSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InfoSource value)?  $default,){
final _that = this;
switch (_that) {
case _InfoSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String? org,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InfoSource() when $default != null:
return $default(_that.label,_that.org,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String? org,  String? url)  $default,) {final _that = this;
switch (_that) {
case _InfoSource():
return $default(_that.label,_that.org,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String? org,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _InfoSource() when $default != null:
return $default(_that.label,_that.org,_that.url);case _:
  return null;

}
}

}

/// @nodoc


class _InfoSource implements InfoSource {
  const _InfoSource({required this.label, this.org, this.url});
  

/// 한국어 표시명(기관·문서명). 예: '질병관리청 예방접종도우미'.
@override final  String label;
/// 발행 기관 축약(선택). 예: 'AAP', 'WHO'.
@override final  String? org;
/// 원문 URL(선택, 검증된 것만 — 앱은 노출하지 않는다).
@override final  String? url;

/// Create a copy of InfoSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InfoSourceCopyWith<_InfoSource> get copyWith => __$InfoSourceCopyWithImpl<_InfoSource>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InfoSource&&(identical(other.label, label) || other.label == label)&&(identical(other.org, org) || other.org == org)&&(identical(other.url, url) || other.url == url));
}


@override
int get hashCode => Object.hash(runtimeType,label,org,url);

@override
String toString() {
  return 'InfoSource(label: $label, org: $org, url: $url)';
}


}

/// @nodoc
abstract mixin class _$InfoSourceCopyWith<$Res> implements $InfoSourceCopyWith<$Res> {
  factory _$InfoSourceCopyWith(_InfoSource value, $Res Function(_InfoSource) _then) = __$InfoSourceCopyWithImpl;
@override @useResult
$Res call({
 String label, String? org, String? url
});




}
/// @nodoc
class __$InfoSourceCopyWithImpl<$Res>
    implements _$InfoSourceCopyWith<$Res> {
  __$InfoSourceCopyWithImpl(this._self, this._then);

  final _InfoSource _self;
  final $Res Function(_InfoSource) _then;

/// Create a copy of InfoSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? org = freezed,Object? url = freezed,}) {
  return _then(_InfoSource(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,org: freezed == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
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
 String get summary;/// `sections` — 섹션형 본문(타입 유니온 [InfoSection]).
 List<InfoSection> get sections;/// `emergency` — 응급신호 배열(없을 수 있음).
 List<EmergencySign> get emergency;/// `sources` — 참고 자료 출처(없을 수 있음 — 비면 상세 화면이 블록 생략).
 List<InfoSource> get sources; DateTime get updatedAt;
/// Create a copy of SymptomInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SymptomInfoCopyWith<SymptomInfo> get copyWith => _$SymptomInfoCopyWithImpl<SymptomInfo>(this as SymptomInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SymptomInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.symptomId, symptomId) || other.symptomId == symptomId)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.emergency, emergency)&&const DeepCollectionEquality().equals(other.sources, sources)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,symptomId,summary,const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(emergency),const DeepCollectionEquality().hash(sources),updatedAt);

@override
String toString() {
  return 'SymptomInfo(id: $id, symptomId: $symptomId, summary: $summary, sections: $sections, emergency: $emergency, sources: $sources, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SymptomInfoCopyWith<$Res>  {
  factory $SymptomInfoCopyWith(SymptomInfo value, $Res Function(SymptomInfo) _then) = _$SymptomInfoCopyWithImpl;
@useResult
$Res call({
 String id, String symptomId, String summary, List<InfoSection> sections, List<EmergencySign> emergency, List<InfoSource> sources, DateTime updatedAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? symptomId = null,Object? summary = null,Object? sections = null,Object? emergency = null,Object? sources = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symptomId: null == symptomId ? _self.symptomId : symptomId // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<InfoSection>,emergency: null == emergency ? _self.emergency : emergency // ignore: cast_nullable_to_non_nullable
as List<EmergencySign>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<InfoSource>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String symptomId,  String summary,  List<InfoSection> sections,  List<EmergencySign> emergency,  List<InfoSource> sources,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SymptomInfo() when $default != null:
return $default(_that.id,_that.symptomId,_that.summary,_that.sections,_that.emergency,_that.sources,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String symptomId,  String summary,  List<InfoSection> sections,  List<EmergencySign> emergency,  List<InfoSource> sources,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SymptomInfo():
return $default(_that.id,_that.symptomId,_that.summary,_that.sections,_that.emergency,_that.sources,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String symptomId,  String summary,  List<InfoSection> sections,  List<EmergencySign> emergency,  List<InfoSource> sources,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SymptomInfo() when $default != null:
return $default(_that.id,_that.symptomId,_that.summary,_that.sections,_that.emergency,_that.sources,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _SymptomInfo extends SymptomInfo {
  const _SymptomInfo({required this.id, required this.symptomId, required this.summary, final  List<InfoSection> sections = const <InfoSection>[], final  List<EmergencySign> emergency = const <EmergencySign>[], final  List<InfoSource> sources = const <InfoSource>[], required this.updatedAt}): _sections = sections,_emergency = emergency,_sources = sources,super._();
  

@override final  String id;
@override final  String symptomId;
/// `summary` — 2~3문장 요약.
@override final  String summary;
/// `sections` — 섹션형 본문(타입 유니온 [InfoSection]).
 final  List<InfoSection> _sections;
/// `sections` — 섹션형 본문(타입 유니온 [InfoSection]).
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

/// `sources` — 참고 자료 출처(없을 수 있음 — 비면 상세 화면이 블록 생략).
 final  List<InfoSource> _sources;
/// `sources` — 참고 자료 출처(없을 수 있음 — 비면 상세 화면이 블록 생략).
@override@JsonKey() List<InfoSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

@override final  DateTime updatedAt;

/// Create a copy of SymptomInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SymptomInfoCopyWith<_SymptomInfo> get copyWith => __$SymptomInfoCopyWithImpl<_SymptomInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SymptomInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.symptomId, symptomId) || other.symptomId == symptomId)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._emergency, _emergency)&&const DeepCollectionEquality().equals(other._sources, _sources)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,symptomId,summary,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_emergency),const DeepCollectionEquality().hash(_sources),updatedAt);

@override
String toString() {
  return 'SymptomInfo(id: $id, symptomId: $symptomId, summary: $summary, sections: $sections, emergency: $emergency, sources: $sources, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SymptomInfoCopyWith<$Res> implements $SymptomInfoCopyWith<$Res> {
  factory _$SymptomInfoCopyWith(_SymptomInfo value, $Res Function(_SymptomInfo) _then) = __$SymptomInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String symptomId, String summary, List<InfoSection> sections, List<EmergencySign> emergency, List<InfoSource> sources, DateTime updatedAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? symptomId = null,Object? summary = null,Object? sections = null,Object? emergency = null,Object? sources = null,Object? updatedAt = null,}) {
  return _then(_SymptomInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,symptomId: null == symptomId ? _self.symptomId : symptomId // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<InfoSection>,emergency: null == emergency ? _self._emergency : emergency // ignore: cast_nullable_to_non_nullable
as List<EmergencySign>,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<InfoSource>,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
