// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatListStreamItem {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatListStreamItem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatListStreamItem()';
}


}

/// @nodoc
class $ChatListStreamItemCopyWith<$Res>  {
$ChatListStreamItemCopyWith(ChatListStreamItem _, $Res Function(ChatListStreamItem) __);
}


/// Adds pattern-matching-related methods to [ChatListStreamItem].
extension ChatListStreamItemPatterns on ChatListStreamItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatListStreamItem_InitialSnapshot value)?  initialSnapshot,TResult Function( ChatListStreamItem_Update value)?  update,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatListStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that);case ChatListStreamItem_Update() when update != null:
return update(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatListStreamItem_InitialSnapshot value)  initialSnapshot,required TResult Function( ChatListStreamItem_Update value)  update,}){
final _that = this;
switch (_that) {
case ChatListStreamItem_InitialSnapshot():
return initialSnapshot(_that);case ChatListStreamItem_Update():
return update(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatListStreamItem_InitialSnapshot value)?  initialSnapshot,TResult? Function( ChatListStreamItem_Update value)?  update,}){
final _that = this;
switch (_that) {
case ChatListStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that);case ChatListStreamItem_Update() when update != null:
return update(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<ChatSummary> items)?  initialSnapshot,TResult Function( ChatListUpdate update)?  update,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatListStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that.items);case ChatListStreamItem_Update() when update != null:
return update(_that.update);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<ChatSummary> items)  initialSnapshot,required TResult Function( ChatListUpdate update)  update,}) {final _that = this;
switch (_that) {
case ChatListStreamItem_InitialSnapshot():
return initialSnapshot(_that.items);case ChatListStreamItem_Update():
return update(_that.update);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<ChatSummary> items)?  initialSnapshot,TResult? Function( ChatListUpdate update)?  update,}) {final _that = this;
switch (_that) {
case ChatListStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that.items);case ChatListStreamItem_Update() when update != null:
return update(_that.update);case _:
  return null;

}
}

}

/// @nodoc


class ChatListStreamItem_InitialSnapshot extends ChatListStreamItem {
  const ChatListStreamItem_InitialSnapshot({required final  List<ChatSummary> items}): _items = items,super._();
  

 final  List<ChatSummary> _items;
 List<ChatSummary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ChatListStreamItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatListStreamItem_InitialSnapshotCopyWith<ChatListStreamItem_InitialSnapshot> get copyWith => _$ChatListStreamItem_InitialSnapshotCopyWithImpl<ChatListStreamItem_InitialSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatListStreamItem_InitialSnapshot&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ChatListStreamItem.initialSnapshot(items: $items)';
}


}

/// @nodoc
abstract mixin class $ChatListStreamItem_InitialSnapshotCopyWith<$Res> implements $ChatListStreamItemCopyWith<$Res> {
  factory $ChatListStreamItem_InitialSnapshotCopyWith(ChatListStreamItem_InitialSnapshot value, $Res Function(ChatListStreamItem_InitialSnapshot) _then) = _$ChatListStreamItem_InitialSnapshotCopyWithImpl;
@useResult
$Res call({
 List<ChatSummary> items
});




}
/// @nodoc
class _$ChatListStreamItem_InitialSnapshotCopyWithImpl<$Res>
    implements $ChatListStreamItem_InitialSnapshotCopyWith<$Res> {
  _$ChatListStreamItem_InitialSnapshotCopyWithImpl(this._self, this._then);

  final ChatListStreamItem_InitialSnapshot _self;
  final $Res Function(ChatListStreamItem_InitialSnapshot) _then;

/// Create a copy of ChatListStreamItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(ChatListStreamItem_InitialSnapshot(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ChatSummary>,
  ));
}


}

/// @nodoc


class ChatListStreamItem_Update extends ChatListStreamItem {
  const ChatListStreamItem_Update({required this.update}): super._();
  

 final  ChatListUpdate update;

/// Create a copy of ChatListStreamItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatListStreamItem_UpdateCopyWith<ChatListStreamItem_Update> get copyWith => _$ChatListStreamItem_UpdateCopyWithImpl<ChatListStreamItem_Update>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatListStreamItem_Update&&(identical(other.update, update) || other.update == update));
}


@override
int get hashCode => Object.hash(runtimeType,update);

@override
String toString() {
  return 'ChatListStreamItem.update(update: $update)';
}


}

/// @nodoc
abstract mixin class $ChatListStreamItem_UpdateCopyWith<$Res> implements $ChatListStreamItemCopyWith<$Res> {
  factory $ChatListStreamItem_UpdateCopyWith(ChatListStreamItem_Update value, $Res Function(ChatListStreamItem_Update) _then) = _$ChatListStreamItem_UpdateCopyWithImpl;
@useResult
$Res call({
 ChatListUpdate update
});




}
/// @nodoc
class _$ChatListStreamItem_UpdateCopyWithImpl<$Res>
    implements $ChatListStreamItem_UpdateCopyWith<$Res> {
  _$ChatListStreamItem_UpdateCopyWithImpl(this._self, this._then);

  final ChatListStreamItem_Update _self;
  final $Res Function(ChatListStreamItem_Update) _then;

/// Create a copy of ChatListStreamItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? update = null,}) {
  return _then(ChatListStreamItem_Update(
update: null == update ? _self.update : update // ignore: cast_nullable_to_non_nullable
as ChatListUpdate,
  ));
}


}

/// @nodoc
mixin _$ChatMuteDuration {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMuteDuration);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMuteDuration()';
}


}

/// @nodoc
class $ChatMuteDurationCopyWith<$Res>  {
$ChatMuteDurationCopyWith(ChatMuteDuration _, $Res Function(ChatMuteDuration) __);
}


/// Adds pattern-matching-related methods to [ChatMuteDuration].
extension ChatMuteDurationPatterns on ChatMuteDuration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatMuteDuration_OneHour value)?  oneHour,TResult Function( ChatMuteDuration_EightHours value)?  eightHours,TResult Function( ChatMuteDuration_OneDay value)?  oneDay,TResult Function( ChatMuteDuration_OneWeek value)?  oneWeek,TResult Function( ChatMuteDuration_Forever value)?  forever,TResult Function( ChatMuteDuration_Custom value)?  custom,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatMuteDuration_OneHour() when oneHour != null:
return oneHour(_that);case ChatMuteDuration_EightHours() when eightHours != null:
return eightHours(_that);case ChatMuteDuration_OneDay() when oneDay != null:
return oneDay(_that);case ChatMuteDuration_OneWeek() when oneWeek != null:
return oneWeek(_that);case ChatMuteDuration_Forever() when forever != null:
return forever(_that);case ChatMuteDuration_Custom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatMuteDuration_OneHour value)  oneHour,required TResult Function( ChatMuteDuration_EightHours value)  eightHours,required TResult Function( ChatMuteDuration_OneDay value)  oneDay,required TResult Function( ChatMuteDuration_OneWeek value)  oneWeek,required TResult Function( ChatMuteDuration_Forever value)  forever,required TResult Function( ChatMuteDuration_Custom value)  custom,}){
final _that = this;
switch (_that) {
case ChatMuteDuration_OneHour():
return oneHour(_that);case ChatMuteDuration_EightHours():
return eightHours(_that);case ChatMuteDuration_OneDay():
return oneDay(_that);case ChatMuteDuration_OneWeek():
return oneWeek(_that);case ChatMuteDuration_Forever():
return forever(_that);case ChatMuteDuration_Custom():
return custom(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatMuteDuration_OneHour value)?  oneHour,TResult? Function( ChatMuteDuration_EightHours value)?  eightHours,TResult? Function( ChatMuteDuration_OneDay value)?  oneDay,TResult? Function( ChatMuteDuration_OneWeek value)?  oneWeek,TResult? Function( ChatMuteDuration_Forever value)?  forever,TResult? Function( ChatMuteDuration_Custom value)?  custom,}){
final _that = this;
switch (_that) {
case ChatMuteDuration_OneHour() when oneHour != null:
return oneHour(_that);case ChatMuteDuration_EightHours() when eightHours != null:
return eightHours(_that);case ChatMuteDuration_OneDay() when oneDay != null:
return oneDay(_that);case ChatMuteDuration_OneWeek() when oneWeek != null:
return oneWeek(_that);case ChatMuteDuration_Forever() when forever != null:
return forever(_that);case ChatMuteDuration_Custom() when custom != null:
return custom(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  oneHour,TResult Function()?  eightHours,TResult Function()?  oneDay,TResult Function()?  oneWeek,TResult Function()?  forever,TResult Function( DateTime until)?  custom,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatMuteDuration_OneHour() when oneHour != null:
return oneHour();case ChatMuteDuration_EightHours() when eightHours != null:
return eightHours();case ChatMuteDuration_OneDay() when oneDay != null:
return oneDay();case ChatMuteDuration_OneWeek() when oneWeek != null:
return oneWeek();case ChatMuteDuration_Forever() when forever != null:
return forever();case ChatMuteDuration_Custom() when custom != null:
return custom(_that.until);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  oneHour,required TResult Function()  eightHours,required TResult Function()  oneDay,required TResult Function()  oneWeek,required TResult Function()  forever,required TResult Function( DateTime until)  custom,}) {final _that = this;
switch (_that) {
case ChatMuteDuration_OneHour():
return oneHour();case ChatMuteDuration_EightHours():
return eightHours();case ChatMuteDuration_OneDay():
return oneDay();case ChatMuteDuration_OneWeek():
return oneWeek();case ChatMuteDuration_Forever():
return forever();case ChatMuteDuration_Custom():
return custom(_that.until);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  oneHour,TResult? Function()?  eightHours,TResult? Function()?  oneDay,TResult? Function()?  oneWeek,TResult? Function()?  forever,TResult? Function( DateTime until)?  custom,}) {final _that = this;
switch (_that) {
case ChatMuteDuration_OneHour() when oneHour != null:
return oneHour();case ChatMuteDuration_EightHours() when eightHours != null:
return eightHours();case ChatMuteDuration_OneDay() when oneDay != null:
return oneDay();case ChatMuteDuration_OneWeek() when oneWeek != null:
return oneWeek();case ChatMuteDuration_Forever() when forever != null:
return forever();case ChatMuteDuration_Custom() when custom != null:
return custom(_that.until);case _:
  return null;

}
}

}

/// @nodoc


class ChatMuteDuration_OneHour extends ChatMuteDuration {
  const ChatMuteDuration_OneHour(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMuteDuration_OneHour);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMuteDuration.oneHour()';
}


}




/// @nodoc


class ChatMuteDuration_EightHours extends ChatMuteDuration {
  const ChatMuteDuration_EightHours(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMuteDuration_EightHours);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMuteDuration.eightHours()';
}


}




/// @nodoc


class ChatMuteDuration_OneDay extends ChatMuteDuration {
  const ChatMuteDuration_OneDay(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMuteDuration_OneDay);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMuteDuration.oneDay()';
}


}




/// @nodoc


class ChatMuteDuration_OneWeek extends ChatMuteDuration {
  const ChatMuteDuration_OneWeek(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMuteDuration_OneWeek);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMuteDuration.oneWeek()';
}


}




/// @nodoc


class ChatMuteDuration_Forever extends ChatMuteDuration {
  const ChatMuteDuration_Forever(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMuteDuration_Forever);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatMuteDuration.forever()';
}


}




/// @nodoc


class ChatMuteDuration_Custom extends ChatMuteDuration {
  const ChatMuteDuration_Custom({required this.until}): super._();
  

 final  DateTime until;

/// Create a copy of ChatMuteDuration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMuteDuration_CustomCopyWith<ChatMuteDuration_Custom> get copyWith => _$ChatMuteDuration_CustomCopyWithImpl<ChatMuteDuration_Custom>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMuteDuration_Custom&&(identical(other.until, until) || other.until == until));
}


@override
int get hashCode => Object.hash(runtimeType,until);

@override
String toString() {
  return 'ChatMuteDuration.custom(until: $until)';
}


}

/// @nodoc
abstract mixin class $ChatMuteDuration_CustomCopyWith<$Res> implements $ChatMuteDurationCopyWith<$Res> {
  factory $ChatMuteDuration_CustomCopyWith(ChatMuteDuration_Custom value, $Res Function(ChatMuteDuration_Custom) _then) = _$ChatMuteDuration_CustomCopyWithImpl;
@useResult
$Res call({
 DateTime until
});




}
/// @nodoc
class _$ChatMuteDuration_CustomCopyWithImpl<$Res>
    implements $ChatMuteDuration_CustomCopyWith<$Res> {
  _$ChatMuteDuration_CustomCopyWithImpl(this._self, this._then);

  final ChatMuteDuration_Custom _self;
  final $Res Function(ChatMuteDuration_Custom) _then;

/// Create a copy of ChatMuteDuration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? until = null,}) {
  return _then(ChatMuteDuration_Custom(
until: null == until ? _self.until : until // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
