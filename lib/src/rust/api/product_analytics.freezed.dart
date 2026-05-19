// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_analytics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductAnalyticsBackend {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductAnalyticsBackend);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductAnalyticsBackend()';
}


}

/// @nodoc
class $ProductAnalyticsBackendCopyWith<$Res>  {
$ProductAnalyticsBackendCopyWith(ProductAnalyticsBackend _, $Res Function(ProductAnalyticsBackend) __);
}


/// Adds pattern-matching-related methods to [ProductAnalyticsBackend].
extension ProductAnalyticsBackendPatterns on ProductAnalyticsBackend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProductAnalyticsBackend_Disabled value)?  disabled,TResult Function( ProductAnalyticsBackend_Aptabase value)?  aptabase,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProductAnalyticsBackend_Disabled() when disabled != null:
return disabled(_that);case ProductAnalyticsBackend_Aptabase() when aptabase != null:
return aptabase(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProductAnalyticsBackend_Disabled value)  disabled,required TResult Function( ProductAnalyticsBackend_Aptabase value)  aptabase,}){
final _that = this;
switch (_that) {
case ProductAnalyticsBackend_Disabled():
return disabled(_that);case ProductAnalyticsBackend_Aptabase():
return aptabase(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProductAnalyticsBackend_Disabled value)?  disabled,TResult? Function( ProductAnalyticsBackend_Aptabase value)?  aptabase,}){
final _that = this;
switch (_that) {
case ProductAnalyticsBackend_Disabled() when disabled != null:
return disabled(_that);case ProductAnalyticsBackend_Aptabase() when aptabase != null:
return aptabase(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  disabled,TResult Function( AptabaseAnalyticsConfig config)?  aptabase,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProductAnalyticsBackend_Disabled() when disabled != null:
return disabled();case ProductAnalyticsBackend_Aptabase() when aptabase != null:
return aptabase(_that.config);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  disabled,required TResult Function( AptabaseAnalyticsConfig config)  aptabase,}) {final _that = this;
switch (_that) {
case ProductAnalyticsBackend_Disabled():
return disabled();case ProductAnalyticsBackend_Aptabase():
return aptabase(_that.config);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  disabled,TResult? Function( AptabaseAnalyticsConfig config)?  aptabase,}) {final _that = this;
switch (_that) {
case ProductAnalyticsBackend_Disabled() when disabled != null:
return disabled();case ProductAnalyticsBackend_Aptabase() when aptabase != null:
return aptabase(_that.config);case _:
  return null;

}
}

}

/// @nodoc


class ProductAnalyticsBackend_Disabled extends ProductAnalyticsBackend {
  const ProductAnalyticsBackend_Disabled(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductAnalyticsBackend_Disabled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductAnalyticsBackend.disabled()';
}


}




/// @nodoc


class ProductAnalyticsBackend_Aptabase extends ProductAnalyticsBackend {
  const ProductAnalyticsBackend_Aptabase({required this.config}): super._();
  

 final  AptabaseAnalyticsConfig config;

/// Create a copy of ProductAnalyticsBackend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductAnalyticsBackend_AptabaseCopyWith<ProductAnalyticsBackend_Aptabase> get copyWith => _$ProductAnalyticsBackend_AptabaseCopyWithImpl<ProductAnalyticsBackend_Aptabase>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductAnalyticsBackend_Aptabase&&(identical(other.config, config) || other.config == config));
}


@override
int get hashCode => Object.hash(runtimeType,config);

@override
String toString() {
  return 'ProductAnalyticsBackend.aptabase(config: $config)';
}


}

/// @nodoc
abstract mixin class $ProductAnalyticsBackend_AptabaseCopyWith<$Res> implements $ProductAnalyticsBackendCopyWith<$Res> {
  factory $ProductAnalyticsBackend_AptabaseCopyWith(ProductAnalyticsBackend_Aptabase value, $Res Function(ProductAnalyticsBackend_Aptabase) _then) = _$ProductAnalyticsBackend_AptabaseCopyWithImpl;
@useResult
$Res call({
 AptabaseAnalyticsConfig config
});




}
/// @nodoc
class _$ProductAnalyticsBackend_AptabaseCopyWithImpl<$Res>
    implements $ProductAnalyticsBackend_AptabaseCopyWith<$Res> {
  _$ProductAnalyticsBackend_AptabaseCopyWithImpl(this._self, this._then);

  final ProductAnalyticsBackend_Aptabase _self;
  final $Res Function(ProductAnalyticsBackend_Aptabase) _then;

/// Create a copy of ProductAnalyticsBackend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? config = null,}) {
  return _then(ProductAnalyticsBackend_Aptabase(
config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as AptabaseAnalyticsConfig,
  ));
}


}

// dart format on
