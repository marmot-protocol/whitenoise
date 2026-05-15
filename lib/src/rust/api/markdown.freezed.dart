// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'markdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MarkdownBlock {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarkdownBlock()';
}


}

/// @nodoc
class $MarkdownBlockCopyWith<$Res>  {
$MarkdownBlockCopyWith(MarkdownBlock _, $Res Function(MarkdownBlock) __);
}


/// Adds pattern-matching-related methods to [MarkdownBlock].
extension MarkdownBlockPatterns on MarkdownBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarkdownBlock_Paragraph value)?  paragraph,TResult Function( MarkdownBlock_Heading value)?  heading,TResult Function( MarkdownBlock_ThematicBreak value)?  thematicBreak,TResult Function( MarkdownBlock_CodeBlock value)?  codeBlock,TResult Function( MarkdownBlock_BlockQuote value)?  blockQuote,TResult Function( MarkdownBlock_List value)?  list,TResult Function( MarkdownBlock_Table value)?  table,TResult Function( MarkdownBlock_MathBlock value)?  mathBlock,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarkdownBlock_Paragraph() when paragraph != null:
return paragraph(_that);case MarkdownBlock_Heading() when heading != null:
return heading(_that);case MarkdownBlock_ThematicBreak() when thematicBreak != null:
return thematicBreak(_that);case MarkdownBlock_CodeBlock() when codeBlock != null:
return codeBlock(_that);case MarkdownBlock_BlockQuote() when blockQuote != null:
return blockQuote(_that);case MarkdownBlock_List() when list != null:
return list(_that);case MarkdownBlock_Table() when table != null:
return table(_that);case MarkdownBlock_MathBlock() when mathBlock != null:
return mathBlock(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarkdownBlock_Paragraph value)  paragraph,required TResult Function( MarkdownBlock_Heading value)  heading,required TResult Function( MarkdownBlock_ThematicBreak value)  thematicBreak,required TResult Function( MarkdownBlock_CodeBlock value)  codeBlock,required TResult Function( MarkdownBlock_BlockQuote value)  blockQuote,required TResult Function( MarkdownBlock_List value)  list,required TResult Function( MarkdownBlock_Table value)  table,required TResult Function( MarkdownBlock_MathBlock value)  mathBlock,}){
final _that = this;
switch (_that) {
case MarkdownBlock_Paragraph():
return paragraph(_that);case MarkdownBlock_Heading():
return heading(_that);case MarkdownBlock_ThematicBreak():
return thematicBreak(_that);case MarkdownBlock_CodeBlock():
return codeBlock(_that);case MarkdownBlock_BlockQuote():
return blockQuote(_that);case MarkdownBlock_List():
return list(_that);case MarkdownBlock_Table():
return table(_that);case MarkdownBlock_MathBlock():
return mathBlock(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarkdownBlock_Paragraph value)?  paragraph,TResult? Function( MarkdownBlock_Heading value)?  heading,TResult? Function( MarkdownBlock_ThematicBreak value)?  thematicBreak,TResult? Function( MarkdownBlock_CodeBlock value)?  codeBlock,TResult? Function( MarkdownBlock_BlockQuote value)?  blockQuote,TResult? Function( MarkdownBlock_List value)?  list,TResult? Function( MarkdownBlock_Table value)?  table,TResult? Function( MarkdownBlock_MathBlock value)?  mathBlock,}){
final _that = this;
switch (_that) {
case MarkdownBlock_Paragraph() when paragraph != null:
return paragraph(_that);case MarkdownBlock_Heading() when heading != null:
return heading(_that);case MarkdownBlock_ThematicBreak() when thematicBreak != null:
return thematicBreak(_that);case MarkdownBlock_CodeBlock() when codeBlock != null:
return codeBlock(_that);case MarkdownBlock_BlockQuote() when blockQuote != null:
return blockQuote(_that);case MarkdownBlock_List() when list != null:
return list(_that);case MarkdownBlock_Table() when table != null:
return table(_that);case MarkdownBlock_MathBlock() when mathBlock != null:
return mathBlock(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<MarkdownInline> inlines)?  paragraph,TResult Function( int level,  List<MarkdownInline> inlines)?  heading,TResult Function()?  thematicBreak,TResult Function( MarkdownCodeBlockKind kind,  String info,  String content)?  codeBlock,TResult Function( List<MarkdownBlock> blocks)?  blockQuote,TResult Function( MarkdownListKind kind,  bool tight,  List<MarkdownListItem> items)?  list,TResult Function( List<MarkdownAlignment> alignments,  List<MarkdownTableCell> header,  List<List<MarkdownTableCell>> rows)?  table,TResult Function( String content)?  mathBlock,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarkdownBlock_Paragraph() when paragraph != null:
return paragraph(_that.inlines);case MarkdownBlock_Heading() when heading != null:
return heading(_that.level,_that.inlines);case MarkdownBlock_ThematicBreak() when thematicBreak != null:
return thematicBreak();case MarkdownBlock_CodeBlock() when codeBlock != null:
return codeBlock(_that.kind,_that.info,_that.content);case MarkdownBlock_BlockQuote() when blockQuote != null:
return blockQuote(_that.blocks);case MarkdownBlock_List() when list != null:
return list(_that.kind,_that.tight,_that.items);case MarkdownBlock_Table() when table != null:
return table(_that.alignments,_that.header,_that.rows);case MarkdownBlock_MathBlock() when mathBlock != null:
return mathBlock(_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<MarkdownInline> inlines)  paragraph,required TResult Function( int level,  List<MarkdownInline> inlines)  heading,required TResult Function()  thematicBreak,required TResult Function( MarkdownCodeBlockKind kind,  String info,  String content)  codeBlock,required TResult Function( List<MarkdownBlock> blocks)  blockQuote,required TResult Function( MarkdownListKind kind,  bool tight,  List<MarkdownListItem> items)  list,required TResult Function( List<MarkdownAlignment> alignments,  List<MarkdownTableCell> header,  List<List<MarkdownTableCell>> rows)  table,required TResult Function( String content)  mathBlock,}) {final _that = this;
switch (_that) {
case MarkdownBlock_Paragraph():
return paragraph(_that.inlines);case MarkdownBlock_Heading():
return heading(_that.level,_that.inlines);case MarkdownBlock_ThematicBreak():
return thematicBreak();case MarkdownBlock_CodeBlock():
return codeBlock(_that.kind,_that.info,_that.content);case MarkdownBlock_BlockQuote():
return blockQuote(_that.blocks);case MarkdownBlock_List():
return list(_that.kind,_that.tight,_that.items);case MarkdownBlock_Table():
return table(_that.alignments,_that.header,_that.rows);case MarkdownBlock_MathBlock():
return mathBlock(_that.content);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<MarkdownInline> inlines)?  paragraph,TResult? Function( int level,  List<MarkdownInline> inlines)?  heading,TResult? Function()?  thematicBreak,TResult? Function( MarkdownCodeBlockKind kind,  String info,  String content)?  codeBlock,TResult? Function( List<MarkdownBlock> blocks)?  blockQuote,TResult? Function( MarkdownListKind kind,  bool tight,  List<MarkdownListItem> items)?  list,TResult? Function( List<MarkdownAlignment> alignments,  List<MarkdownTableCell> header,  List<List<MarkdownTableCell>> rows)?  table,TResult? Function( String content)?  mathBlock,}) {final _that = this;
switch (_that) {
case MarkdownBlock_Paragraph() when paragraph != null:
return paragraph(_that.inlines);case MarkdownBlock_Heading() when heading != null:
return heading(_that.level,_that.inlines);case MarkdownBlock_ThematicBreak() when thematicBreak != null:
return thematicBreak();case MarkdownBlock_CodeBlock() when codeBlock != null:
return codeBlock(_that.kind,_that.info,_that.content);case MarkdownBlock_BlockQuote() when blockQuote != null:
return blockQuote(_that.blocks);case MarkdownBlock_List() when list != null:
return list(_that.kind,_that.tight,_that.items);case MarkdownBlock_Table() when table != null:
return table(_that.alignments,_that.header,_that.rows);case MarkdownBlock_MathBlock() when mathBlock != null:
return mathBlock(_that.content);case _:
  return null;

}
}

}

/// @nodoc


class MarkdownBlock_Paragraph extends MarkdownBlock {
  const MarkdownBlock_Paragraph({required final  List<MarkdownInline> inlines}): _inlines = inlines,super._();
  

 final  List<MarkdownInline> _inlines;
 List<MarkdownInline> get inlines {
  if (_inlines is EqualUnmodifiableListView) return _inlines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inlines);
}


/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownBlock_ParagraphCopyWith<MarkdownBlock_Paragraph> get copyWith => _$MarkdownBlock_ParagraphCopyWithImpl<MarkdownBlock_Paragraph>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_Paragraph&&const DeepCollectionEquality().equals(other._inlines, _inlines));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_inlines));

@override
String toString() {
  return 'MarkdownBlock.paragraph(inlines: $inlines)';
}


}

/// @nodoc
abstract mixin class $MarkdownBlock_ParagraphCopyWith<$Res> implements $MarkdownBlockCopyWith<$Res> {
  factory $MarkdownBlock_ParagraphCopyWith(MarkdownBlock_Paragraph value, $Res Function(MarkdownBlock_Paragraph) _then) = _$MarkdownBlock_ParagraphCopyWithImpl;
@useResult
$Res call({
 List<MarkdownInline> inlines
});




}
/// @nodoc
class _$MarkdownBlock_ParagraphCopyWithImpl<$Res>
    implements $MarkdownBlock_ParagraphCopyWith<$Res> {
  _$MarkdownBlock_ParagraphCopyWithImpl(this._self, this._then);

  final MarkdownBlock_Paragraph _self;
  final $Res Function(MarkdownBlock_Paragraph) _then;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? inlines = null,}) {
  return _then(MarkdownBlock_Paragraph(
inlines: null == inlines ? _self._inlines : inlines // ignore: cast_nullable_to_non_nullable
as List<MarkdownInline>,
  ));
}


}

/// @nodoc


class MarkdownBlock_Heading extends MarkdownBlock {
  const MarkdownBlock_Heading({required this.level, required final  List<MarkdownInline> inlines}): _inlines = inlines,super._();
  

 final  int level;
 final  List<MarkdownInline> _inlines;
 List<MarkdownInline> get inlines {
  if (_inlines is EqualUnmodifiableListView) return _inlines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inlines);
}


/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownBlock_HeadingCopyWith<MarkdownBlock_Heading> get copyWith => _$MarkdownBlock_HeadingCopyWithImpl<MarkdownBlock_Heading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_Heading&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other._inlines, _inlines));
}


@override
int get hashCode => Object.hash(runtimeType,level,const DeepCollectionEquality().hash(_inlines));

@override
String toString() {
  return 'MarkdownBlock.heading(level: $level, inlines: $inlines)';
}


}

/// @nodoc
abstract mixin class $MarkdownBlock_HeadingCopyWith<$Res> implements $MarkdownBlockCopyWith<$Res> {
  factory $MarkdownBlock_HeadingCopyWith(MarkdownBlock_Heading value, $Res Function(MarkdownBlock_Heading) _then) = _$MarkdownBlock_HeadingCopyWithImpl;
@useResult
$Res call({
 int level, List<MarkdownInline> inlines
});




}
/// @nodoc
class _$MarkdownBlock_HeadingCopyWithImpl<$Res>
    implements $MarkdownBlock_HeadingCopyWith<$Res> {
  _$MarkdownBlock_HeadingCopyWithImpl(this._self, this._then);

  final MarkdownBlock_Heading _self;
  final $Res Function(MarkdownBlock_Heading) _then;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? level = null,Object? inlines = null,}) {
  return _then(MarkdownBlock_Heading(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,inlines: null == inlines ? _self._inlines : inlines // ignore: cast_nullable_to_non_nullable
as List<MarkdownInline>,
  ));
}


}

/// @nodoc


class MarkdownBlock_ThematicBreak extends MarkdownBlock {
  const MarkdownBlock_ThematicBreak(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_ThematicBreak);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarkdownBlock.thematicBreak()';
}


}




/// @nodoc


class MarkdownBlock_CodeBlock extends MarkdownBlock {
  const MarkdownBlock_CodeBlock({required this.kind, required this.info, required this.content}): super._();
  

 final  MarkdownCodeBlockKind kind;
 final  String info;
 final  String content;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownBlock_CodeBlockCopyWith<MarkdownBlock_CodeBlock> get copyWith => _$MarkdownBlock_CodeBlockCopyWithImpl<MarkdownBlock_CodeBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_CodeBlock&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.info, info) || other.info == info)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,kind,info,content);

@override
String toString() {
  return 'MarkdownBlock.codeBlock(kind: $kind, info: $info, content: $content)';
}


}

/// @nodoc
abstract mixin class $MarkdownBlock_CodeBlockCopyWith<$Res> implements $MarkdownBlockCopyWith<$Res> {
  factory $MarkdownBlock_CodeBlockCopyWith(MarkdownBlock_CodeBlock value, $Res Function(MarkdownBlock_CodeBlock) _then) = _$MarkdownBlock_CodeBlockCopyWithImpl;
@useResult
$Res call({
 MarkdownCodeBlockKind kind, String info, String content
});




}
/// @nodoc
class _$MarkdownBlock_CodeBlockCopyWithImpl<$Res>
    implements $MarkdownBlock_CodeBlockCopyWith<$Res> {
  _$MarkdownBlock_CodeBlockCopyWithImpl(this._self, this._then);

  final MarkdownBlock_CodeBlock _self;
  final $Res Function(MarkdownBlock_CodeBlock) _then;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? info = null,Object? content = null,}) {
  return _then(MarkdownBlock_CodeBlock(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MarkdownCodeBlockKind,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarkdownBlock_BlockQuote extends MarkdownBlock {
  const MarkdownBlock_BlockQuote({required final  List<MarkdownBlock> blocks}): _blocks = blocks,super._();
  

 final  List<MarkdownBlock> _blocks;
 List<MarkdownBlock> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}


/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownBlock_BlockQuoteCopyWith<MarkdownBlock_BlockQuote> get copyWith => _$MarkdownBlock_BlockQuoteCopyWithImpl<MarkdownBlock_BlockQuote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_BlockQuote&&const DeepCollectionEquality().equals(other._blocks, _blocks));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_blocks));

@override
String toString() {
  return 'MarkdownBlock.blockQuote(blocks: $blocks)';
}


}

/// @nodoc
abstract mixin class $MarkdownBlock_BlockQuoteCopyWith<$Res> implements $MarkdownBlockCopyWith<$Res> {
  factory $MarkdownBlock_BlockQuoteCopyWith(MarkdownBlock_BlockQuote value, $Res Function(MarkdownBlock_BlockQuote) _then) = _$MarkdownBlock_BlockQuoteCopyWithImpl;
@useResult
$Res call({
 List<MarkdownBlock> blocks
});




}
/// @nodoc
class _$MarkdownBlock_BlockQuoteCopyWithImpl<$Res>
    implements $MarkdownBlock_BlockQuoteCopyWith<$Res> {
  _$MarkdownBlock_BlockQuoteCopyWithImpl(this._self, this._then);

  final MarkdownBlock_BlockQuote _self;
  final $Res Function(MarkdownBlock_BlockQuote) _then;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? blocks = null,}) {
  return _then(MarkdownBlock_BlockQuote(
blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<MarkdownBlock>,
  ));
}


}

/// @nodoc


class MarkdownBlock_List extends MarkdownBlock {
  const MarkdownBlock_List({required this.kind, required this.tight, required final  List<MarkdownListItem> items}): _items = items,super._();
  

 final  MarkdownListKind kind;
 final  bool tight;
 final  List<MarkdownListItem> _items;
 List<MarkdownListItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownBlock_ListCopyWith<MarkdownBlock_List> get copyWith => _$MarkdownBlock_ListCopyWithImpl<MarkdownBlock_List>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_List&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.tight, tight) || other.tight == tight)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,kind,tight,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'MarkdownBlock.list(kind: $kind, tight: $tight, items: $items)';
}


}

/// @nodoc
abstract mixin class $MarkdownBlock_ListCopyWith<$Res> implements $MarkdownBlockCopyWith<$Res> {
  factory $MarkdownBlock_ListCopyWith(MarkdownBlock_List value, $Res Function(MarkdownBlock_List) _then) = _$MarkdownBlock_ListCopyWithImpl;
@useResult
$Res call({
 MarkdownListKind kind, bool tight, List<MarkdownListItem> items
});


$MarkdownListKindCopyWith<$Res> get kind;

}
/// @nodoc
class _$MarkdownBlock_ListCopyWithImpl<$Res>
    implements $MarkdownBlock_ListCopyWith<$Res> {
  _$MarkdownBlock_ListCopyWithImpl(this._self, this._then);

  final MarkdownBlock_List _self;
  final $Res Function(MarkdownBlock_List) _then;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? tight = null,Object? items = null,}) {
  return _then(MarkdownBlock_List(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MarkdownListKind,tight: null == tight ? _self.tight : tight // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MarkdownListItem>,
  ));
}

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MarkdownListKindCopyWith<$Res> get kind {
  
  return $MarkdownListKindCopyWith<$Res>(_self.kind, (value) {
    return _then(_self.copyWith(kind: value));
  });
}
}

/// @nodoc


class MarkdownBlock_Table extends MarkdownBlock {
  const MarkdownBlock_Table({required final  List<MarkdownAlignment> alignments, required final  List<MarkdownTableCell> header, required final  List<List<MarkdownTableCell>> rows}): _alignments = alignments,_header = header,_rows = rows,super._();
  

 final  List<MarkdownAlignment> _alignments;
 List<MarkdownAlignment> get alignments {
  if (_alignments is EqualUnmodifiableListView) return _alignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alignments);
}

 final  List<MarkdownTableCell> _header;
 List<MarkdownTableCell> get header {
  if (_header is EqualUnmodifiableListView) return _header;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_header);
}

 final  List<List<MarkdownTableCell>> _rows;
 List<List<MarkdownTableCell>> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}


/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownBlock_TableCopyWith<MarkdownBlock_Table> get copyWith => _$MarkdownBlock_TableCopyWithImpl<MarkdownBlock_Table>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_Table&&const DeepCollectionEquality().equals(other._alignments, _alignments)&&const DeepCollectionEquality().equals(other._header, _header)&&const DeepCollectionEquality().equals(other._rows, _rows));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_alignments),const DeepCollectionEquality().hash(_header),const DeepCollectionEquality().hash(_rows));

@override
String toString() {
  return 'MarkdownBlock.table(alignments: $alignments, header: $header, rows: $rows)';
}


}

/// @nodoc
abstract mixin class $MarkdownBlock_TableCopyWith<$Res> implements $MarkdownBlockCopyWith<$Res> {
  factory $MarkdownBlock_TableCopyWith(MarkdownBlock_Table value, $Res Function(MarkdownBlock_Table) _then) = _$MarkdownBlock_TableCopyWithImpl;
@useResult
$Res call({
 List<MarkdownAlignment> alignments, List<MarkdownTableCell> header, List<List<MarkdownTableCell>> rows
});




}
/// @nodoc
class _$MarkdownBlock_TableCopyWithImpl<$Res>
    implements $MarkdownBlock_TableCopyWith<$Res> {
  _$MarkdownBlock_TableCopyWithImpl(this._self, this._then);

  final MarkdownBlock_Table _self;
  final $Res Function(MarkdownBlock_Table) _then;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? alignments = null,Object? header = null,Object? rows = null,}) {
  return _then(MarkdownBlock_Table(
alignments: null == alignments ? _self._alignments : alignments // ignore: cast_nullable_to_non_nullable
as List<MarkdownAlignment>,header: null == header ? _self._header : header // ignore: cast_nullable_to_non_nullable
as List<MarkdownTableCell>,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<List<MarkdownTableCell>>,
  ));
}


}

/// @nodoc


class MarkdownBlock_MathBlock extends MarkdownBlock {
  const MarkdownBlock_MathBlock({required this.content}): super._();
  

 final  String content;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownBlock_MathBlockCopyWith<MarkdownBlock_MathBlock> get copyWith => _$MarkdownBlock_MathBlockCopyWithImpl<MarkdownBlock_MathBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownBlock_MathBlock&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,content);

@override
String toString() {
  return 'MarkdownBlock.mathBlock(content: $content)';
}


}

/// @nodoc
abstract mixin class $MarkdownBlock_MathBlockCopyWith<$Res> implements $MarkdownBlockCopyWith<$Res> {
  factory $MarkdownBlock_MathBlockCopyWith(MarkdownBlock_MathBlock value, $Res Function(MarkdownBlock_MathBlock) _then) = _$MarkdownBlock_MathBlockCopyWithImpl;
@useResult
$Res call({
 String content
});




}
/// @nodoc
class _$MarkdownBlock_MathBlockCopyWithImpl<$Res>
    implements $MarkdownBlock_MathBlockCopyWith<$Res> {
  _$MarkdownBlock_MathBlockCopyWithImpl(this._self, this._then);

  final MarkdownBlock_MathBlock _self;
  final $Res Function(MarkdownBlock_MathBlock) _then;

/// Create a copy of MarkdownBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? content = null,}) {
  return _then(MarkdownBlock_MathBlock(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$MarkdownInline {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarkdownInline()';
}


}

/// @nodoc
class $MarkdownInlineCopyWith<$Res>  {
$MarkdownInlineCopyWith(MarkdownInline _, $Res Function(MarkdownInline) __);
}


/// Adds pattern-matching-related methods to [MarkdownInline].
extension MarkdownInlinePatterns on MarkdownInline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarkdownInline_Text value)?  text,TResult Function( MarkdownInline_SoftBreak value)?  softBreak,TResult Function( MarkdownInline_HardBreak value)?  hardBreak,TResult Function( MarkdownInline_Code value)?  code,TResult Function( MarkdownInline_Emph value)?  emph,TResult Function( MarkdownInline_Strong value)?  strong,TResult Function( MarkdownInline_Strikethrough value)?  strikethrough,TResult Function( MarkdownInline_Link value)?  link,TResult Function( MarkdownInline_Image value)?  image,TResult Function( MarkdownInline_Autolink value)?  autolink,TResult Function( MarkdownInline_Math value)?  math,TResult Function( MarkdownInline_NostrMention value)?  nostrMention,TResult Function( MarkdownInline_NostrUri value)?  nostrUri,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarkdownInline_Text() when text != null:
return text(_that);case MarkdownInline_SoftBreak() when softBreak != null:
return softBreak(_that);case MarkdownInline_HardBreak() when hardBreak != null:
return hardBreak(_that);case MarkdownInline_Code() when code != null:
return code(_that);case MarkdownInline_Emph() when emph != null:
return emph(_that);case MarkdownInline_Strong() when strong != null:
return strong(_that);case MarkdownInline_Strikethrough() when strikethrough != null:
return strikethrough(_that);case MarkdownInline_Link() when link != null:
return link(_that);case MarkdownInline_Image() when image != null:
return image(_that);case MarkdownInline_Autolink() when autolink != null:
return autolink(_that);case MarkdownInline_Math() when math != null:
return math(_that);case MarkdownInline_NostrMention() when nostrMention != null:
return nostrMention(_that);case MarkdownInline_NostrUri() when nostrUri != null:
return nostrUri(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarkdownInline_Text value)  text,required TResult Function( MarkdownInline_SoftBreak value)  softBreak,required TResult Function( MarkdownInline_HardBreak value)  hardBreak,required TResult Function( MarkdownInline_Code value)  code,required TResult Function( MarkdownInline_Emph value)  emph,required TResult Function( MarkdownInline_Strong value)  strong,required TResult Function( MarkdownInline_Strikethrough value)  strikethrough,required TResult Function( MarkdownInline_Link value)  link,required TResult Function( MarkdownInline_Image value)  image,required TResult Function( MarkdownInline_Autolink value)  autolink,required TResult Function( MarkdownInline_Math value)  math,required TResult Function( MarkdownInline_NostrMention value)  nostrMention,required TResult Function( MarkdownInline_NostrUri value)  nostrUri,}){
final _that = this;
switch (_that) {
case MarkdownInline_Text():
return text(_that);case MarkdownInline_SoftBreak():
return softBreak(_that);case MarkdownInline_HardBreak():
return hardBreak(_that);case MarkdownInline_Code():
return code(_that);case MarkdownInline_Emph():
return emph(_that);case MarkdownInline_Strong():
return strong(_that);case MarkdownInline_Strikethrough():
return strikethrough(_that);case MarkdownInline_Link():
return link(_that);case MarkdownInline_Image():
return image(_that);case MarkdownInline_Autolink():
return autolink(_that);case MarkdownInline_Math():
return math(_that);case MarkdownInline_NostrMention():
return nostrMention(_that);case MarkdownInline_NostrUri():
return nostrUri(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarkdownInline_Text value)?  text,TResult? Function( MarkdownInline_SoftBreak value)?  softBreak,TResult? Function( MarkdownInline_HardBreak value)?  hardBreak,TResult? Function( MarkdownInline_Code value)?  code,TResult? Function( MarkdownInline_Emph value)?  emph,TResult? Function( MarkdownInline_Strong value)?  strong,TResult? Function( MarkdownInline_Strikethrough value)?  strikethrough,TResult? Function( MarkdownInline_Link value)?  link,TResult? Function( MarkdownInline_Image value)?  image,TResult? Function( MarkdownInline_Autolink value)?  autolink,TResult? Function( MarkdownInline_Math value)?  math,TResult? Function( MarkdownInline_NostrMention value)?  nostrMention,TResult? Function( MarkdownInline_NostrUri value)?  nostrUri,}){
final _that = this;
switch (_that) {
case MarkdownInline_Text() when text != null:
return text(_that);case MarkdownInline_SoftBreak() when softBreak != null:
return softBreak(_that);case MarkdownInline_HardBreak() when hardBreak != null:
return hardBreak(_that);case MarkdownInline_Code() when code != null:
return code(_that);case MarkdownInline_Emph() when emph != null:
return emph(_that);case MarkdownInline_Strong() when strong != null:
return strong(_that);case MarkdownInline_Strikethrough() when strikethrough != null:
return strikethrough(_that);case MarkdownInline_Link() when link != null:
return link(_that);case MarkdownInline_Image() when image != null:
return image(_that);case MarkdownInline_Autolink() when autolink != null:
return autolink(_that);case MarkdownInline_Math() when math != null:
return math(_that);case MarkdownInline_NostrMention() when nostrMention != null:
return nostrMention(_that);case MarkdownInline_NostrUri() when nostrUri != null:
return nostrUri(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String content)?  text,TResult Function()?  softBreak,TResult Function()?  hardBreak,TResult Function( String content)?  code,TResult Function( List<MarkdownInline> children)?  emph,TResult Function( List<MarkdownInline> children)?  strong,TResult Function( List<MarkdownInline> children)?  strikethrough,TResult Function( String dest,  String? title,  List<MarkdownInline> children)?  link,TResult Function( String dest,  String? title,  List<MarkdownInline> alt)?  image,TResult Function( String url,  MarkdownAutolinkKind kind)?  autolink,TResult Function( String content)?  math,TResult Function( MarkdownNostrEntity entity)?  nostrMention,TResult Function( MarkdownNostrEntity entity)?  nostrUri,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarkdownInline_Text() when text != null:
return text(_that.content);case MarkdownInline_SoftBreak() when softBreak != null:
return softBreak();case MarkdownInline_HardBreak() when hardBreak != null:
return hardBreak();case MarkdownInline_Code() when code != null:
return code(_that.content);case MarkdownInline_Emph() when emph != null:
return emph(_that.children);case MarkdownInline_Strong() when strong != null:
return strong(_that.children);case MarkdownInline_Strikethrough() when strikethrough != null:
return strikethrough(_that.children);case MarkdownInline_Link() when link != null:
return link(_that.dest,_that.title,_that.children);case MarkdownInline_Image() when image != null:
return image(_that.dest,_that.title,_that.alt);case MarkdownInline_Autolink() when autolink != null:
return autolink(_that.url,_that.kind);case MarkdownInline_Math() when math != null:
return math(_that.content);case MarkdownInline_NostrMention() when nostrMention != null:
return nostrMention(_that.entity);case MarkdownInline_NostrUri() when nostrUri != null:
return nostrUri(_that.entity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String content)  text,required TResult Function()  softBreak,required TResult Function()  hardBreak,required TResult Function( String content)  code,required TResult Function( List<MarkdownInline> children)  emph,required TResult Function( List<MarkdownInline> children)  strong,required TResult Function( List<MarkdownInline> children)  strikethrough,required TResult Function( String dest,  String? title,  List<MarkdownInline> children)  link,required TResult Function( String dest,  String? title,  List<MarkdownInline> alt)  image,required TResult Function( String url,  MarkdownAutolinkKind kind)  autolink,required TResult Function( String content)  math,required TResult Function( MarkdownNostrEntity entity)  nostrMention,required TResult Function( MarkdownNostrEntity entity)  nostrUri,}) {final _that = this;
switch (_that) {
case MarkdownInline_Text():
return text(_that.content);case MarkdownInline_SoftBreak():
return softBreak();case MarkdownInline_HardBreak():
return hardBreak();case MarkdownInline_Code():
return code(_that.content);case MarkdownInline_Emph():
return emph(_that.children);case MarkdownInline_Strong():
return strong(_that.children);case MarkdownInline_Strikethrough():
return strikethrough(_that.children);case MarkdownInline_Link():
return link(_that.dest,_that.title,_that.children);case MarkdownInline_Image():
return image(_that.dest,_that.title,_that.alt);case MarkdownInline_Autolink():
return autolink(_that.url,_that.kind);case MarkdownInline_Math():
return math(_that.content);case MarkdownInline_NostrMention():
return nostrMention(_that.entity);case MarkdownInline_NostrUri():
return nostrUri(_that.entity);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String content)?  text,TResult? Function()?  softBreak,TResult? Function()?  hardBreak,TResult? Function( String content)?  code,TResult? Function( List<MarkdownInline> children)?  emph,TResult? Function( List<MarkdownInline> children)?  strong,TResult? Function( List<MarkdownInline> children)?  strikethrough,TResult? Function( String dest,  String? title,  List<MarkdownInline> children)?  link,TResult? Function( String dest,  String? title,  List<MarkdownInline> alt)?  image,TResult? Function( String url,  MarkdownAutolinkKind kind)?  autolink,TResult? Function( String content)?  math,TResult? Function( MarkdownNostrEntity entity)?  nostrMention,TResult? Function( MarkdownNostrEntity entity)?  nostrUri,}) {final _that = this;
switch (_that) {
case MarkdownInline_Text() when text != null:
return text(_that.content);case MarkdownInline_SoftBreak() when softBreak != null:
return softBreak();case MarkdownInline_HardBreak() when hardBreak != null:
return hardBreak();case MarkdownInline_Code() when code != null:
return code(_that.content);case MarkdownInline_Emph() when emph != null:
return emph(_that.children);case MarkdownInline_Strong() when strong != null:
return strong(_that.children);case MarkdownInline_Strikethrough() when strikethrough != null:
return strikethrough(_that.children);case MarkdownInline_Link() when link != null:
return link(_that.dest,_that.title,_that.children);case MarkdownInline_Image() when image != null:
return image(_that.dest,_that.title,_that.alt);case MarkdownInline_Autolink() when autolink != null:
return autolink(_that.url,_that.kind);case MarkdownInline_Math() when math != null:
return math(_that.content);case MarkdownInline_NostrMention() when nostrMention != null:
return nostrMention(_that.entity);case MarkdownInline_NostrUri() when nostrUri != null:
return nostrUri(_that.entity);case _:
  return null;

}
}

}

/// @nodoc


class MarkdownInline_Text extends MarkdownInline {
  const MarkdownInline_Text({required this.content}): super._();
  

 final  String content;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_TextCopyWith<MarkdownInline_Text> get copyWith => _$MarkdownInline_TextCopyWithImpl<MarkdownInline_Text>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Text&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,content);

@override
String toString() {
  return 'MarkdownInline.text(content: $content)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_TextCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_TextCopyWith(MarkdownInline_Text value, $Res Function(MarkdownInline_Text) _then) = _$MarkdownInline_TextCopyWithImpl;
@useResult
$Res call({
 String content
});




}
/// @nodoc
class _$MarkdownInline_TextCopyWithImpl<$Res>
    implements $MarkdownInline_TextCopyWith<$Res> {
  _$MarkdownInline_TextCopyWithImpl(this._self, this._then);

  final MarkdownInline_Text _self;
  final $Res Function(MarkdownInline_Text) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? content = null,}) {
  return _then(MarkdownInline_Text(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarkdownInline_SoftBreak extends MarkdownInline {
  const MarkdownInline_SoftBreak(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_SoftBreak);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarkdownInline.softBreak()';
}


}




/// @nodoc


class MarkdownInline_HardBreak extends MarkdownInline {
  const MarkdownInline_HardBreak(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_HardBreak);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarkdownInline.hardBreak()';
}


}




/// @nodoc


class MarkdownInline_Code extends MarkdownInline {
  const MarkdownInline_Code({required this.content}): super._();
  

 final  String content;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_CodeCopyWith<MarkdownInline_Code> get copyWith => _$MarkdownInline_CodeCopyWithImpl<MarkdownInline_Code>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Code&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,content);

@override
String toString() {
  return 'MarkdownInline.code(content: $content)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_CodeCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_CodeCopyWith(MarkdownInline_Code value, $Res Function(MarkdownInline_Code) _then) = _$MarkdownInline_CodeCopyWithImpl;
@useResult
$Res call({
 String content
});




}
/// @nodoc
class _$MarkdownInline_CodeCopyWithImpl<$Res>
    implements $MarkdownInline_CodeCopyWith<$Res> {
  _$MarkdownInline_CodeCopyWithImpl(this._self, this._then);

  final MarkdownInline_Code _self;
  final $Res Function(MarkdownInline_Code) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? content = null,}) {
  return _then(MarkdownInline_Code(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarkdownInline_Emph extends MarkdownInline {
  const MarkdownInline_Emph({required final  List<MarkdownInline> children}): _children = children,super._();
  

 final  List<MarkdownInline> _children;
 List<MarkdownInline> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_EmphCopyWith<MarkdownInline_Emph> get copyWith => _$MarkdownInline_EmphCopyWithImpl<MarkdownInline_Emph>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Emph&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MarkdownInline.emph(children: $children)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_EmphCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_EmphCopyWith(MarkdownInline_Emph value, $Res Function(MarkdownInline_Emph) _then) = _$MarkdownInline_EmphCopyWithImpl;
@useResult
$Res call({
 List<MarkdownInline> children
});




}
/// @nodoc
class _$MarkdownInline_EmphCopyWithImpl<$Res>
    implements $MarkdownInline_EmphCopyWith<$Res> {
  _$MarkdownInline_EmphCopyWithImpl(this._self, this._then);

  final MarkdownInline_Emph _self;
  final $Res Function(MarkdownInline_Emph) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(MarkdownInline_Emph(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MarkdownInline>,
  ));
}


}

/// @nodoc


class MarkdownInline_Strong extends MarkdownInline {
  const MarkdownInline_Strong({required final  List<MarkdownInline> children}): _children = children,super._();
  

 final  List<MarkdownInline> _children;
 List<MarkdownInline> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_StrongCopyWith<MarkdownInline_Strong> get copyWith => _$MarkdownInline_StrongCopyWithImpl<MarkdownInline_Strong>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Strong&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MarkdownInline.strong(children: $children)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_StrongCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_StrongCopyWith(MarkdownInline_Strong value, $Res Function(MarkdownInline_Strong) _then) = _$MarkdownInline_StrongCopyWithImpl;
@useResult
$Res call({
 List<MarkdownInline> children
});




}
/// @nodoc
class _$MarkdownInline_StrongCopyWithImpl<$Res>
    implements $MarkdownInline_StrongCopyWith<$Res> {
  _$MarkdownInline_StrongCopyWithImpl(this._self, this._then);

  final MarkdownInline_Strong _self;
  final $Res Function(MarkdownInline_Strong) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(MarkdownInline_Strong(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MarkdownInline>,
  ));
}


}

/// @nodoc


class MarkdownInline_Strikethrough extends MarkdownInline {
  const MarkdownInline_Strikethrough({required final  List<MarkdownInline> children}): _children = children,super._();
  

 final  List<MarkdownInline> _children;
 List<MarkdownInline> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_StrikethroughCopyWith<MarkdownInline_Strikethrough> get copyWith => _$MarkdownInline_StrikethroughCopyWithImpl<MarkdownInline_Strikethrough>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Strikethrough&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MarkdownInline.strikethrough(children: $children)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_StrikethroughCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_StrikethroughCopyWith(MarkdownInline_Strikethrough value, $Res Function(MarkdownInline_Strikethrough) _then) = _$MarkdownInline_StrikethroughCopyWithImpl;
@useResult
$Res call({
 List<MarkdownInline> children
});




}
/// @nodoc
class _$MarkdownInline_StrikethroughCopyWithImpl<$Res>
    implements $MarkdownInline_StrikethroughCopyWith<$Res> {
  _$MarkdownInline_StrikethroughCopyWithImpl(this._self, this._then);

  final MarkdownInline_Strikethrough _self;
  final $Res Function(MarkdownInline_Strikethrough) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(MarkdownInline_Strikethrough(
children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MarkdownInline>,
  ));
}


}

/// @nodoc


class MarkdownInline_Link extends MarkdownInline {
  const MarkdownInline_Link({required this.dest, this.title, required final  List<MarkdownInline> children}): _children = children,super._();
  

 final  String dest;
 final  String? title;
 final  List<MarkdownInline> _children;
 List<MarkdownInline> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_LinkCopyWith<MarkdownInline_Link> get copyWith => _$MarkdownInline_LinkCopyWithImpl<MarkdownInline_Link>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Link&&(identical(other.dest, dest) || other.dest == dest)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,dest,title,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MarkdownInline.link(dest: $dest, title: $title, children: $children)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_LinkCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_LinkCopyWith(MarkdownInline_Link value, $Res Function(MarkdownInline_Link) _then) = _$MarkdownInline_LinkCopyWithImpl;
@useResult
$Res call({
 String dest, String? title, List<MarkdownInline> children
});




}
/// @nodoc
class _$MarkdownInline_LinkCopyWithImpl<$Res>
    implements $MarkdownInline_LinkCopyWith<$Res> {
  _$MarkdownInline_LinkCopyWithImpl(this._self, this._then);

  final MarkdownInline_Link _self;
  final $Res Function(MarkdownInline_Link) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dest = null,Object? title = freezed,Object? children = null,}) {
  return _then(MarkdownInline_Link(
dest: null == dest ? _self.dest : dest // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MarkdownInline>,
  ));
}


}

/// @nodoc


class MarkdownInline_Image extends MarkdownInline {
  const MarkdownInline_Image({required this.dest, this.title, required final  List<MarkdownInline> alt}): _alt = alt,super._();
  

 final  String dest;
 final  String? title;
 final  List<MarkdownInline> _alt;
 List<MarkdownInline> get alt {
  if (_alt is EqualUnmodifiableListView) return _alt;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alt);
}


/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_ImageCopyWith<MarkdownInline_Image> get copyWith => _$MarkdownInline_ImageCopyWithImpl<MarkdownInline_Image>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Image&&(identical(other.dest, dest) || other.dest == dest)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._alt, _alt));
}


@override
int get hashCode => Object.hash(runtimeType,dest,title,const DeepCollectionEquality().hash(_alt));

@override
String toString() {
  return 'MarkdownInline.image(dest: $dest, title: $title, alt: $alt)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_ImageCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_ImageCopyWith(MarkdownInline_Image value, $Res Function(MarkdownInline_Image) _then) = _$MarkdownInline_ImageCopyWithImpl;
@useResult
$Res call({
 String dest, String? title, List<MarkdownInline> alt
});




}
/// @nodoc
class _$MarkdownInline_ImageCopyWithImpl<$Res>
    implements $MarkdownInline_ImageCopyWith<$Res> {
  _$MarkdownInline_ImageCopyWithImpl(this._self, this._then);

  final MarkdownInline_Image _self;
  final $Res Function(MarkdownInline_Image) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dest = null,Object? title = freezed,Object? alt = null,}) {
  return _then(MarkdownInline_Image(
dest: null == dest ? _self.dest : dest // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,alt: null == alt ? _self._alt : alt // ignore: cast_nullable_to_non_nullable
as List<MarkdownInline>,
  ));
}


}

/// @nodoc


class MarkdownInline_Autolink extends MarkdownInline {
  const MarkdownInline_Autolink({required this.url, required this.kind}): super._();
  

 final  String url;
 final  MarkdownAutolinkKind kind;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_AutolinkCopyWith<MarkdownInline_Autolink> get copyWith => _$MarkdownInline_AutolinkCopyWithImpl<MarkdownInline_Autolink>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Autolink&&(identical(other.url, url) || other.url == url)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,url,kind);

@override
String toString() {
  return 'MarkdownInline.autolink(url: $url, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_AutolinkCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_AutolinkCopyWith(MarkdownInline_Autolink value, $Res Function(MarkdownInline_Autolink) _then) = _$MarkdownInline_AutolinkCopyWithImpl;
@useResult
$Res call({
 String url, MarkdownAutolinkKind kind
});




}
/// @nodoc
class _$MarkdownInline_AutolinkCopyWithImpl<$Res>
    implements $MarkdownInline_AutolinkCopyWith<$Res> {
  _$MarkdownInline_AutolinkCopyWithImpl(this._self, this._then);

  final MarkdownInline_Autolink _self;
  final $Res Function(MarkdownInline_Autolink) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,Object? kind = null,}) {
  return _then(MarkdownInline_Autolink(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MarkdownAutolinkKind,
  ));
}


}

/// @nodoc


class MarkdownInline_Math extends MarkdownInline {
  const MarkdownInline_Math({required this.content}): super._();
  

 final  String content;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_MathCopyWith<MarkdownInline_Math> get copyWith => _$MarkdownInline_MathCopyWithImpl<MarkdownInline_Math>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_Math&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,content);

@override
String toString() {
  return 'MarkdownInline.math(content: $content)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_MathCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_MathCopyWith(MarkdownInline_Math value, $Res Function(MarkdownInline_Math) _then) = _$MarkdownInline_MathCopyWithImpl;
@useResult
$Res call({
 String content
});




}
/// @nodoc
class _$MarkdownInline_MathCopyWithImpl<$Res>
    implements $MarkdownInline_MathCopyWith<$Res> {
  _$MarkdownInline_MathCopyWithImpl(this._self, this._then);

  final MarkdownInline_Math _self;
  final $Res Function(MarkdownInline_Math) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? content = null,}) {
  return _then(MarkdownInline_Math(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarkdownInline_NostrMention extends MarkdownInline {
  const MarkdownInline_NostrMention({required this.entity}): super._();
  

 final  MarkdownNostrEntity entity;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_NostrMentionCopyWith<MarkdownInline_NostrMention> get copyWith => _$MarkdownInline_NostrMentionCopyWithImpl<MarkdownInline_NostrMention>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_NostrMention&&(identical(other.entity, entity) || other.entity == entity));
}


@override
int get hashCode => Object.hash(runtimeType,entity);

@override
String toString() {
  return 'MarkdownInline.nostrMention(entity: $entity)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_NostrMentionCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_NostrMentionCopyWith(MarkdownInline_NostrMention value, $Res Function(MarkdownInline_NostrMention) _then) = _$MarkdownInline_NostrMentionCopyWithImpl;
@useResult
$Res call({
 MarkdownNostrEntity entity
});




}
/// @nodoc
class _$MarkdownInline_NostrMentionCopyWithImpl<$Res>
    implements $MarkdownInline_NostrMentionCopyWith<$Res> {
  _$MarkdownInline_NostrMentionCopyWithImpl(this._self, this._then);

  final MarkdownInline_NostrMention _self;
  final $Res Function(MarkdownInline_NostrMention) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entity = null,}) {
  return _then(MarkdownInline_NostrMention(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as MarkdownNostrEntity,
  ));
}


}

/// @nodoc


class MarkdownInline_NostrUri extends MarkdownInline {
  const MarkdownInline_NostrUri({required this.entity}): super._();
  

 final  MarkdownNostrEntity entity;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownInline_NostrUriCopyWith<MarkdownInline_NostrUri> get copyWith => _$MarkdownInline_NostrUriCopyWithImpl<MarkdownInline_NostrUri>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownInline_NostrUri&&(identical(other.entity, entity) || other.entity == entity));
}


@override
int get hashCode => Object.hash(runtimeType,entity);

@override
String toString() {
  return 'MarkdownInline.nostrUri(entity: $entity)';
}


}

/// @nodoc
abstract mixin class $MarkdownInline_NostrUriCopyWith<$Res> implements $MarkdownInlineCopyWith<$Res> {
  factory $MarkdownInline_NostrUriCopyWith(MarkdownInline_NostrUri value, $Res Function(MarkdownInline_NostrUri) _then) = _$MarkdownInline_NostrUriCopyWithImpl;
@useResult
$Res call({
 MarkdownNostrEntity entity
});




}
/// @nodoc
class _$MarkdownInline_NostrUriCopyWithImpl<$Res>
    implements $MarkdownInline_NostrUriCopyWith<$Res> {
  _$MarkdownInline_NostrUriCopyWithImpl(this._self, this._then);

  final MarkdownInline_NostrUri _self;
  final $Res Function(MarkdownInline_NostrUri) _then;

/// Create a copy of MarkdownInline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entity = null,}) {
  return _then(MarkdownInline_NostrUri(
entity: null == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as MarkdownNostrEntity,
  ));
}


}

/// @nodoc
mixin _$MarkdownListKind {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownListKind);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarkdownListKind()';
}


}

/// @nodoc
class $MarkdownListKindCopyWith<$Res>  {
$MarkdownListKindCopyWith(MarkdownListKind _, $Res Function(MarkdownListKind) __);
}


/// Adds pattern-matching-related methods to [MarkdownListKind].
extension MarkdownListKindPatterns on MarkdownListKind {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarkdownListKind_Bullet value)?  bullet,TResult Function( MarkdownListKind_Ordered value)?  ordered,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarkdownListKind_Bullet() when bullet != null:
return bullet(_that);case MarkdownListKind_Ordered() when ordered != null:
return ordered(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarkdownListKind_Bullet value)  bullet,required TResult Function( MarkdownListKind_Ordered value)  ordered,}){
final _that = this;
switch (_that) {
case MarkdownListKind_Bullet():
return bullet(_that);case MarkdownListKind_Ordered():
return ordered(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarkdownListKind_Bullet value)?  bullet,TResult? Function( MarkdownListKind_Ordered value)?  ordered,}){
final _that = this;
switch (_that) {
case MarkdownListKind_Bullet() when bullet != null:
return bullet(_that);case MarkdownListKind_Ordered() when ordered != null:
return ordered(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String marker)?  bullet,TResult Function( int start,  String delimiter)?  ordered,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarkdownListKind_Bullet() when bullet != null:
return bullet(_that.marker);case MarkdownListKind_Ordered() when ordered != null:
return ordered(_that.start,_that.delimiter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String marker)  bullet,required TResult Function( int start,  String delimiter)  ordered,}) {final _that = this;
switch (_that) {
case MarkdownListKind_Bullet():
return bullet(_that.marker);case MarkdownListKind_Ordered():
return ordered(_that.start,_that.delimiter);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String marker)?  bullet,TResult? Function( int start,  String delimiter)?  ordered,}) {final _that = this;
switch (_that) {
case MarkdownListKind_Bullet() when bullet != null:
return bullet(_that.marker);case MarkdownListKind_Ordered() when ordered != null:
return ordered(_that.start,_that.delimiter);case _:
  return null;

}
}

}

/// @nodoc


class MarkdownListKind_Bullet extends MarkdownListKind {
  const MarkdownListKind_Bullet({required this.marker}): super._();
  

 final  String marker;

/// Create a copy of MarkdownListKind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownListKind_BulletCopyWith<MarkdownListKind_Bullet> get copyWith => _$MarkdownListKind_BulletCopyWithImpl<MarkdownListKind_Bullet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownListKind_Bullet&&(identical(other.marker, marker) || other.marker == marker));
}


@override
int get hashCode => Object.hash(runtimeType,marker);

@override
String toString() {
  return 'MarkdownListKind.bullet(marker: $marker)';
}


}

/// @nodoc
abstract mixin class $MarkdownListKind_BulletCopyWith<$Res> implements $MarkdownListKindCopyWith<$Res> {
  factory $MarkdownListKind_BulletCopyWith(MarkdownListKind_Bullet value, $Res Function(MarkdownListKind_Bullet) _then) = _$MarkdownListKind_BulletCopyWithImpl;
@useResult
$Res call({
 String marker
});




}
/// @nodoc
class _$MarkdownListKind_BulletCopyWithImpl<$Res>
    implements $MarkdownListKind_BulletCopyWith<$Res> {
  _$MarkdownListKind_BulletCopyWithImpl(this._self, this._then);

  final MarkdownListKind_Bullet _self;
  final $Res Function(MarkdownListKind_Bullet) _then;

/// Create a copy of MarkdownListKind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? marker = null,}) {
  return _then(MarkdownListKind_Bullet(
marker: null == marker ? _self.marker : marker // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarkdownListKind_Ordered extends MarkdownListKind {
  const MarkdownListKind_Ordered({required this.start, required this.delimiter}): super._();
  

 final  int start;
 final  String delimiter;

/// Create a copy of MarkdownListKind
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownListKind_OrderedCopyWith<MarkdownListKind_Ordered> get copyWith => _$MarkdownListKind_OrderedCopyWithImpl<MarkdownListKind_Ordered>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownListKind_Ordered&&(identical(other.start, start) || other.start == start)&&(identical(other.delimiter, delimiter) || other.delimiter == delimiter));
}


@override
int get hashCode => Object.hash(runtimeType,start,delimiter);

@override
String toString() {
  return 'MarkdownListKind.ordered(start: $start, delimiter: $delimiter)';
}


}

/// @nodoc
abstract mixin class $MarkdownListKind_OrderedCopyWith<$Res> implements $MarkdownListKindCopyWith<$Res> {
  factory $MarkdownListKind_OrderedCopyWith(MarkdownListKind_Ordered value, $Res Function(MarkdownListKind_Ordered) _then) = _$MarkdownListKind_OrderedCopyWithImpl;
@useResult
$Res call({
 int start, String delimiter
});




}
/// @nodoc
class _$MarkdownListKind_OrderedCopyWithImpl<$Res>
    implements $MarkdownListKind_OrderedCopyWith<$Res> {
  _$MarkdownListKind_OrderedCopyWithImpl(this._self, this._then);

  final MarkdownListKind_Ordered _self;
  final $Res Function(MarkdownListKind_Ordered) _then;

/// Create a copy of MarkdownListKind
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? start = null,Object? delimiter = null,}) {
  return _then(MarkdownListKind_Ordered(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,delimiter: null == delimiter ? _self.delimiter : delimiter // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
