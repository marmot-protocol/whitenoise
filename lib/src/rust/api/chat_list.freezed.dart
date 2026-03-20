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

// dart format on
