// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'users.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserStreamItem {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserStreamItem);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserStreamItem()';
}


}

/// @nodoc
class $UserStreamItemCopyWith<$Res>  {
$UserStreamItemCopyWith(UserStreamItem _, $Res Function(UserStreamItem) __);
}


/// Adds pattern-matching-related methods to [UserStreamItem].
extension UserStreamItemPatterns on UserStreamItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserStreamItem_InitialSnapshot value)?  initialSnapshot,TResult Function( UserStreamItem_Update value)?  update,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that);case UserStreamItem_Update() when update != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserStreamItem_InitialSnapshot value)  initialSnapshot,required TResult Function( UserStreamItem_Update value)  update,}){
final _that = this;
switch (_that) {
case UserStreamItem_InitialSnapshot():
return initialSnapshot(_that);case UserStreamItem_Update():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserStreamItem_InitialSnapshot value)?  initialSnapshot,TResult? Function( UserStreamItem_Update value)?  update,}){
final _that = this;
switch (_that) {
case UserStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that);case UserStreamItem_Update() when update != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( User user)?  initialSnapshot,TResult Function( UserUpdate update)?  update,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that.user);case UserStreamItem_Update() when update != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( User user)  initialSnapshot,required TResult Function( UserUpdate update)  update,}) {final _that = this;
switch (_that) {
case UserStreamItem_InitialSnapshot():
return initialSnapshot(_that.user);case UserStreamItem_Update():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( User user)?  initialSnapshot,TResult? Function( UserUpdate update)?  update,}) {final _that = this;
switch (_that) {
case UserStreamItem_InitialSnapshot() when initialSnapshot != null:
return initialSnapshot(_that.user);case UserStreamItem_Update() when update != null:
return update(_that.update);case _:
  return null;

}
}

}

/// @nodoc


class UserStreamItem_InitialSnapshot extends UserStreamItem {
  const UserStreamItem_InitialSnapshot({required this.user}): super._();
  

 final  User user;

/// Create a copy of UserStreamItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserStreamItem_InitialSnapshotCopyWith<UserStreamItem_InitialSnapshot> get copyWith => _$UserStreamItem_InitialSnapshotCopyWithImpl<UserStreamItem_InitialSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserStreamItem_InitialSnapshot&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'UserStreamItem.initialSnapshot(user: $user)';
}


}

/// @nodoc
abstract mixin class $UserStreamItem_InitialSnapshotCopyWith<$Res> implements $UserStreamItemCopyWith<$Res> {
  factory $UserStreamItem_InitialSnapshotCopyWith(UserStreamItem_InitialSnapshot value, $Res Function(UserStreamItem_InitialSnapshot) _then) = _$UserStreamItem_InitialSnapshotCopyWithImpl;
@useResult
$Res call({
 User user
});




}
/// @nodoc
class _$UserStreamItem_InitialSnapshotCopyWithImpl<$Res>
    implements $UserStreamItem_InitialSnapshotCopyWith<$Res> {
  _$UserStreamItem_InitialSnapshotCopyWithImpl(this._self, this._then);

  final UserStreamItem_InitialSnapshot _self;
  final $Res Function(UserStreamItem_InitialSnapshot) _then;

/// Create a copy of UserStreamItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(UserStreamItem_InitialSnapshot(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}


}

/// @nodoc


class UserStreamItem_Update extends UserStreamItem {
  const UserStreamItem_Update({required this.update}): super._();
  

 final  UserUpdate update;

/// Create a copy of UserStreamItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserStreamItem_UpdateCopyWith<UserStreamItem_Update> get copyWith => _$UserStreamItem_UpdateCopyWithImpl<UserStreamItem_Update>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserStreamItem_Update&&(identical(other.update, update) || other.update == update));
}


@override
int get hashCode => Object.hash(runtimeType,update);

@override
String toString() {
  return 'UserStreamItem.update(update: $update)';
}


}

/// @nodoc
abstract mixin class $UserStreamItem_UpdateCopyWith<$Res> implements $UserStreamItemCopyWith<$Res> {
  factory $UserStreamItem_UpdateCopyWith(UserStreamItem_Update value, $Res Function(UserStreamItem_Update) _then) = _$UserStreamItem_UpdateCopyWithImpl;
@useResult
$Res call({
 UserUpdate update
});




}
/// @nodoc
class _$UserStreamItem_UpdateCopyWithImpl<$Res>
    implements $UserStreamItem_UpdateCopyWith<$Res> {
  _$UserStreamItem_UpdateCopyWithImpl(this._self, this._then);

  final UserStreamItem_Update _self;
  final $Res Function(UserStreamItem_Update) _then;

/// Create a copy of UserStreamItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? update = null,}) {
  return _then(UserStreamItem_Update(
update: null == update ? _self.update : update // ignore: cast_nullable_to_non_nullable
as UserUpdate,
  ));
}


}

// dart format on
