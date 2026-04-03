import 'package:whitenoise/src/rust/api/messages.dart';

const searchContextSize = 2;

enum SearchDisplayItemType { match, context, separator }

class SearchDisplayItem {
  final SearchDisplayItemType type;
  final ChatMessage? message;
  final List<HighlightSpan>? highlightSpans;
  final int? matchIndex;
  final int? position;

  const SearchDisplayItem._({
    required this.type,
    this.message,
    this.highlightSpans,
    this.matchIndex,
    this.position,
  });

  factory SearchDisplayItem.match({
    required ChatMessage message,
    required List<HighlightSpan> highlightSpans,
    required int matchIndex,
    required int position,
  }) => SearchDisplayItem._(
    type: SearchDisplayItemType.match,
    message: message,
    highlightSpans: highlightSpans,
    matchIndex: matchIndex,
    position: position,
  );

  factory SearchDisplayItem.context({required ChatMessage message}) =>
      SearchDisplayItem._(type: SearchDisplayItemType.context, message: message);

  factory SearchDisplayItem.separator() =>
      const SearchDisplayItem._(type: SearchDisplayItemType.separator);

  bool get isSeparator => type == SearchDisplayItemType.separator;
  bool get isMatch => type == SearchDisplayItemType.match;
}

List<SearchDisplayItem> buildSearchDisplayList({
  required List<SearchResult> results,
  required List<List<ChatMessage>> contextWindows,
}) {
  if (results.isEmpty) return [];

  final matchByMsgId = <String, ({SearchResult result, int matchIndex})>{};
  for (var i = 0; i < results.length; i++) {
    matchByMsgId[results[i].message.id] = (result: results[i], matchIndex: i);
  }

  final mergedGroups = <List<ChatMessage>>[];

  for (final window in contextWindows) {
    if (window.isEmpty) continue;
    if (mergedGroups.isEmpty) {
      mergedGroups.add([...window]);
      continue;
    }
    final prev = mergedGroups.last;
    final prevIds = {for (final m in prev) m.id};
    final overlapOrAdjacent = window.any((m) => prevIds.contains(m.id));
    if (overlapOrAdjacent) {
      for (final m in window) {
        if (!prevIds.contains(m.id)) {
          prev.add(m);
          prevIds.add(m.id);
        }
      }
    } else {
      mergedGroups.add([...window]);
    }
  }

  final items = <SearchDisplayItem>[];
  for (var gi = 0; gi < mergedGroups.length; gi++) {
    if (gi > 0) items.add(SearchDisplayItem.separator());
    for (final msg in mergedGroups[gi]) {
      final info = matchByMsgId[msg.id];
      if (info != null) {
        items.add(
          SearchDisplayItem.match(
            message: info.result.message,
            highlightSpans: info.result.highlightSpans,
            matchIndex: info.matchIndex,
            position: info.result.position.toInt(),
          ),
        );
      } else {
        items.add(SearchDisplayItem.context(message: msg));
      }
    }
  }

  if (items.isEmpty) {
    for (var i = 0; i < results.length; i++) {
      if (i > 0) items.add(SearchDisplayItem.separator());
      items.add(
        SearchDisplayItem.match(
          message: results[i].message,
          highlightSpans: results[i].highlightSpans,
          matchIndex: i,
          position: results[i].position.toInt(),
        ),
      );
    }
  }

  return items;
}
