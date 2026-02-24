// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchUpdateTrigger {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUpdateTrigger);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchUpdateTrigger()';
}


}

/// @nodoc
class $SearchUpdateTriggerCopyWith<$Res>  {
$SearchUpdateTriggerCopyWith(SearchUpdateTrigger _, $Res Function(SearchUpdateTrigger) __);
}


/// Adds pattern-matching-related methods to [SearchUpdateTrigger].
extension SearchUpdateTriggerPatterns on SearchUpdateTrigger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchUpdateTrigger_RadiusStarted value)?  radiusStarted,TResult Function( SearchUpdateTrigger_ResultsFound value)?  resultsFound,TResult Function( SearchUpdateTrigger_RadiusCompleted value)?  radiusCompleted,TResult Function( SearchUpdateTrigger_RadiusTimeout value)?  radiusTimeout,TResult Function( SearchUpdateTrigger_SearchCompleted value)?  searchCompleted,TResult Function( SearchUpdateTrigger_Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchUpdateTrigger_RadiusStarted() when radiusStarted != null:
return radiusStarted(_that);case SearchUpdateTrigger_ResultsFound() when resultsFound != null:
return resultsFound(_that);case SearchUpdateTrigger_RadiusCompleted() when radiusCompleted != null:
return radiusCompleted(_that);case SearchUpdateTrigger_RadiusTimeout() when radiusTimeout != null:
return radiusTimeout(_that);case SearchUpdateTrigger_SearchCompleted() when searchCompleted != null:
return searchCompleted(_that);case SearchUpdateTrigger_Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchUpdateTrigger_RadiusStarted value)  radiusStarted,required TResult Function( SearchUpdateTrigger_ResultsFound value)  resultsFound,required TResult Function( SearchUpdateTrigger_RadiusCompleted value)  radiusCompleted,required TResult Function( SearchUpdateTrigger_RadiusTimeout value)  radiusTimeout,required TResult Function( SearchUpdateTrigger_SearchCompleted value)  searchCompleted,required TResult Function( SearchUpdateTrigger_Error value)  error,}){
final _that = this;
switch (_that) {
case SearchUpdateTrigger_RadiusStarted():
return radiusStarted(_that);case SearchUpdateTrigger_ResultsFound():
return resultsFound(_that);case SearchUpdateTrigger_RadiusCompleted():
return radiusCompleted(_that);case SearchUpdateTrigger_RadiusTimeout():
return radiusTimeout(_that);case SearchUpdateTrigger_SearchCompleted():
return searchCompleted(_that);case SearchUpdateTrigger_Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchUpdateTrigger_RadiusStarted value)?  radiusStarted,TResult? Function( SearchUpdateTrigger_ResultsFound value)?  resultsFound,TResult? Function( SearchUpdateTrigger_RadiusCompleted value)?  radiusCompleted,TResult? Function( SearchUpdateTrigger_RadiusTimeout value)?  radiusTimeout,TResult? Function( SearchUpdateTrigger_SearchCompleted value)?  searchCompleted,TResult? Function( SearchUpdateTrigger_Error value)?  error,}){
final _that = this;
switch (_that) {
case SearchUpdateTrigger_RadiusStarted() when radiusStarted != null:
return radiusStarted(_that);case SearchUpdateTrigger_ResultsFound() when resultsFound != null:
return resultsFound(_that);case SearchUpdateTrigger_RadiusCompleted() when radiusCompleted != null:
return radiusCompleted(_that);case SearchUpdateTrigger_RadiusTimeout() when radiusTimeout != null:
return radiusTimeout(_that);case SearchUpdateTrigger_SearchCompleted() when searchCompleted != null:
return searchCompleted(_that);case SearchUpdateTrigger_Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int radius)?  radiusStarted,TResult Function()?  resultsFound,TResult Function( int radius,  BigInt totalPubkeysSearched)?  radiusCompleted,TResult Function( int radius)?  radiusTimeout,TResult Function( int finalRadius,  BigInt totalResults)?  searchCompleted,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchUpdateTrigger_RadiusStarted() when radiusStarted != null:
return radiusStarted(_that.radius);case SearchUpdateTrigger_ResultsFound() when resultsFound != null:
return resultsFound();case SearchUpdateTrigger_RadiusCompleted() when radiusCompleted != null:
return radiusCompleted(_that.radius,_that.totalPubkeysSearched);case SearchUpdateTrigger_RadiusTimeout() when radiusTimeout != null:
return radiusTimeout(_that.radius);case SearchUpdateTrigger_SearchCompleted() when searchCompleted != null:
return searchCompleted(_that.finalRadius,_that.totalResults);case SearchUpdateTrigger_Error() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int radius)  radiusStarted,required TResult Function()  resultsFound,required TResult Function( int radius,  BigInt totalPubkeysSearched)  radiusCompleted,required TResult Function( int radius)  radiusTimeout,required TResult Function( int finalRadius,  BigInt totalResults)  searchCompleted,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SearchUpdateTrigger_RadiusStarted():
return radiusStarted(_that.radius);case SearchUpdateTrigger_ResultsFound():
return resultsFound();case SearchUpdateTrigger_RadiusCompleted():
return radiusCompleted(_that.radius,_that.totalPubkeysSearched);case SearchUpdateTrigger_RadiusTimeout():
return radiusTimeout(_that.radius);case SearchUpdateTrigger_SearchCompleted():
return searchCompleted(_that.finalRadius,_that.totalResults);case SearchUpdateTrigger_Error():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int radius)?  radiusStarted,TResult? Function()?  resultsFound,TResult? Function( int radius,  BigInt totalPubkeysSearched)?  radiusCompleted,TResult? Function( int radius)?  radiusTimeout,TResult? Function( int finalRadius,  BigInt totalResults)?  searchCompleted,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SearchUpdateTrigger_RadiusStarted() when radiusStarted != null:
return radiusStarted(_that.radius);case SearchUpdateTrigger_ResultsFound() when resultsFound != null:
return resultsFound();case SearchUpdateTrigger_RadiusCompleted() when radiusCompleted != null:
return radiusCompleted(_that.radius,_that.totalPubkeysSearched);case SearchUpdateTrigger_RadiusTimeout() when radiusTimeout != null:
return radiusTimeout(_that.radius);case SearchUpdateTrigger_SearchCompleted() when searchCompleted != null:
return searchCompleted(_that.finalRadius,_that.totalResults);case SearchUpdateTrigger_Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SearchUpdateTrigger_RadiusStarted extends SearchUpdateTrigger {
  const SearchUpdateTrigger_RadiusStarted({required this.radius}): super._();
  

 final  int radius;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchUpdateTrigger_RadiusStartedCopyWith<SearchUpdateTrigger_RadiusStarted> get copyWith => _$SearchUpdateTrigger_RadiusStartedCopyWithImpl<SearchUpdateTrigger_RadiusStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUpdateTrigger_RadiusStarted&&(identical(other.radius, radius) || other.radius == radius));
}


@override
int get hashCode => Object.hash(runtimeType,radius);

@override
String toString() {
  return 'SearchUpdateTrigger.radiusStarted(radius: $radius)';
}


}

/// @nodoc
abstract mixin class $SearchUpdateTrigger_RadiusStartedCopyWith<$Res> implements $SearchUpdateTriggerCopyWith<$Res> {
  factory $SearchUpdateTrigger_RadiusStartedCopyWith(SearchUpdateTrigger_RadiusStarted value, $Res Function(SearchUpdateTrigger_RadiusStarted) _then) = _$SearchUpdateTrigger_RadiusStartedCopyWithImpl;
@useResult
$Res call({
 int radius
});




}
/// @nodoc
class _$SearchUpdateTrigger_RadiusStartedCopyWithImpl<$Res>
    implements $SearchUpdateTrigger_RadiusStartedCopyWith<$Res> {
  _$SearchUpdateTrigger_RadiusStartedCopyWithImpl(this._self, this._then);

  final SearchUpdateTrigger_RadiusStarted _self;
  final $Res Function(SearchUpdateTrigger_RadiusStarted) _then;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? radius = null,}) {
  return _then(SearchUpdateTrigger_RadiusStarted(
radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SearchUpdateTrigger_ResultsFound extends SearchUpdateTrigger {
  const SearchUpdateTrigger_ResultsFound(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUpdateTrigger_ResultsFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchUpdateTrigger.resultsFound()';
}


}




/// @nodoc


class SearchUpdateTrigger_RadiusCompleted extends SearchUpdateTrigger {
  const SearchUpdateTrigger_RadiusCompleted({required this.radius, required this.totalPubkeysSearched}): super._();
  

 final  int radius;
 final  BigInt totalPubkeysSearched;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchUpdateTrigger_RadiusCompletedCopyWith<SearchUpdateTrigger_RadiusCompleted> get copyWith => _$SearchUpdateTrigger_RadiusCompletedCopyWithImpl<SearchUpdateTrigger_RadiusCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUpdateTrigger_RadiusCompleted&&(identical(other.radius, radius) || other.radius == radius)&&(identical(other.totalPubkeysSearched, totalPubkeysSearched) || other.totalPubkeysSearched == totalPubkeysSearched));
}


@override
int get hashCode => Object.hash(runtimeType,radius,totalPubkeysSearched);

@override
String toString() {
  return 'SearchUpdateTrigger.radiusCompleted(radius: $radius, totalPubkeysSearched: $totalPubkeysSearched)';
}


}

/// @nodoc
abstract mixin class $SearchUpdateTrigger_RadiusCompletedCopyWith<$Res> implements $SearchUpdateTriggerCopyWith<$Res> {
  factory $SearchUpdateTrigger_RadiusCompletedCopyWith(SearchUpdateTrigger_RadiusCompleted value, $Res Function(SearchUpdateTrigger_RadiusCompleted) _then) = _$SearchUpdateTrigger_RadiusCompletedCopyWithImpl;
@useResult
$Res call({
 int radius, BigInt totalPubkeysSearched
});




}
/// @nodoc
class _$SearchUpdateTrigger_RadiusCompletedCopyWithImpl<$Res>
    implements $SearchUpdateTrigger_RadiusCompletedCopyWith<$Res> {
  _$SearchUpdateTrigger_RadiusCompletedCopyWithImpl(this._self, this._then);

  final SearchUpdateTrigger_RadiusCompleted _self;
  final $Res Function(SearchUpdateTrigger_RadiusCompleted) _then;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? radius = null,Object? totalPubkeysSearched = null,}) {
  return _then(SearchUpdateTrigger_RadiusCompleted(
radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as int,totalPubkeysSearched: null == totalPubkeysSearched ? _self.totalPubkeysSearched : totalPubkeysSearched // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class SearchUpdateTrigger_RadiusTimeout extends SearchUpdateTrigger {
  const SearchUpdateTrigger_RadiusTimeout({required this.radius}): super._();
  

 final  int radius;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchUpdateTrigger_RadiusTimeoutCopyWith<SearchUpdateTrigger_RadiusTimeout> get copyWith => _$SearchUpdateTrigger_RadiusTimeoutCopyWithImpl<SearchUpdateTrigger_RadiusTimeout>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUpdateTrigger_RadiusTimeout&&(identical(other.radius, radius) || other.radius == radius));
}


@override
int get hashCode => Object.hash(runtimeType,radius);

@override
String toString() {
  return 'SearchUpdateTrigger.radiusTimeout(radius: $radius)';
}


}

/// @nodoc
abstract mixin class $SearchUpdateTrigger_RadiusTimeoutCopyWith<$Res> implements $SearchUpdateTriggerCopyWith<$Res> {
  factory $SearchUpdateTrigger_RadiusTimeoutCopyWith(SearchUpdateTrigger_RadiusTimeout value, $Res Function(SearchUpdateTrigger_RadiusTimeout) _then) = _$SearchUpdateTrigger_RadiusTimeoutCopyWithImpl;
@useResult
$Res call({
 int radius
});




}
/// @nodoc
class _$SearchUpdateTrigger_RadiusTimeoutCopyWithImpl<$Res>
    implements $SearchUpdateTrigger_RadiusTimeoutCopyWith<$Res> {
  _$SearchUpdateTrigger_RadiusTimeoutCopyWithImpl(this._self, this._then);

  final SearchUpdateTrigger_RadiusTimeout _self;
  final $Res Function(SearchUpdateTrigger_RadiusTimeout) _then;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? radius = null,}) {
  return _then(SearchUpdateTrigger_RadiusTimeout(
radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SearchUpdateTrigger_SearchCompleted extends SearchUpdateTrigger {
  const SearchUpdateTrigger_SearchCompleted({required this.finalRadius, required this.totalResults}): super._();
  

 final  int finalRadius;
 final  BigInt totalResults;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchUpdateTrigger_SearchCompletedCopyWith<SearchUpdateTrigger_SearchCompleted> get copyWith => _$SearchUpdateTrigger_SearchCompletedCopyWithImpl<SearchUpdateTrigger_SearchCompleted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUpdateTrigger_SearchCompleted&&(identical(other.finalRadius, finalRadius) || other.finalRadius == finalRadius)&&(identical(other.totalResults, totalResults) || other.totalResults == totalResults));
}


@override
int get hashCode => Object.hash(runtimeType,finalRadius,totalResults);

@override
String toString() {
  return 'SearchUpdateTrigger.searchCompleted(finalRadius: $finalRadius, totalResults: $totalResults)';
}


}

/// @nodoc
abstract mixin class $SearchUpdateTrigger_SearchCompletedCopyWith<$Res> implements $SearchUpdateTriggerCopyWith<$Res> {
  factory $SearchUpdateTrigger_SearchCompletedCopyWith(SearchUpdateTrigger_SearchCompleted value, $Res Function(SearchUpdateTrigger_SearchCompleted) _then) = _$SearchUpdateTrigger_SearchCompletedCopyWithImpl;
@useResult
$Res call({
 int finalRadius, BigInt totalResults
});




}
/// @nodoc
class _$SearchUpdateTrigger_SearchCompletedCopyWithImpl<$Res>
    implements $SearchUpdateTrigger_SearchCompletedCopyWith<$Res> {
  _$SearchUpdateTrigger_SearchCompletedCopyWithImpl(this._self, this._then);

  final SearchUpdateTrigger_SearchCompleted _self;
  final $Res Function(SearchUpdateTrigger_SearchCompleted) _then;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? finalRadius = null,Object? totalResults = null,}) {
  return _then(SearchUpdateTrigger_SearchCompleted(
finalRadius: null == finalRadius ? _self.finalRadius : finalRadius // ignore: cast_nullable_to_non_nullable
as int,totalResults: null == totalResults ? _self.totalResults : totalResults // ignore: cast_nullable_to_non_nullable
as BigInt,
  ));
}


}

/// @nodoc


class SearchUpdateTrigger_Error extends SearchUpdateTrigger {
  const SearchUpdateTrigger_Error({required this.message}): super._();
  

 final  String message;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchUpdateTrigger_ErrorCopyWith<SearchUpdateTrigger_Error> get copyWith => _$SearchUpdateTrigger_ErrorCopyWithImpl<SearchUpdateTrigger_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUpdateTrigger_Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SearchUpdateTrigger.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SearchUpdateTrigger_ErrorCopyWith<$Res> implements $SearchUpdateTriggerCopyWith<$Res> {
  factory $SearchUpdateTrigger_ErrorCopyWith(SearchUpdateTrigger_Error value, $Res Function(SearchUpdateTrigger_Error) _then) = _$SearchUpdateTrigger_ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SearchUpdateTrigger_ErrorCopyWithImpl<$Res>
    implements $SearchUpdateTrigger_ErrorCopyWith<$Res> {
  _$SearchUpdateTrigger_ErrorCopyWithImpl(this._self, this._then);

  final SearchUpdateTrigger_Error _self;
  final $Res Function(SearchUpdateTrigger_Error) _then;

/// Create a copy of SearchUpdateTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SearchUpdateTrigger_Error(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
