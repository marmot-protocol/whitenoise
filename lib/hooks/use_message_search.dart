import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/search_context.dart';

final _logger = Logger('useMessageSearch');

const _searchDebounceMs = 300;

typedef MessageSearchResult = ({
  List<SearchResult> results,
  List<SearchDisplayItem> displayItems,
  bool isSearching,
});

MessageSearchResult useMessageSearch({
  required String pubkey,
  required String groupId,
  required String query,
}) {
  final results = useState<List<SearchResult>>([]);
  final displayItems = useState<List<SearchDisplayItem>>([]);
  final isSearching = useState(false);
  final debouncedQuery = _useDebouncedValue(query, _searchDebounceMs);

  useEffect(() {
    if (debouncedQuery.isEmpty) {
      results.value = [];
      displayItems.value = [];
      isSearching.value = false;
      return null;
    }

    isSearching.value = true;
    var cancelled = false;

    searchMessagesInGroup(
          pubkey: pubkey,
          groupId: groupId,
          query: debouncedQuery,
        )
        .then((searchResults) async {
          if (cancelled) return;
          _logger.info(
            'search completed groupId=${groupId.substring(0, 8)}… '
            'queryLength=${debouncedQuery.length} results=${searchResults.length}',
          );
          results.value = searchResults;

          if (searchResults.isEmpty) {
            displayItems.value = [];
            isSearching.value = false;
            return;
          }

          displayItems.value = _matchOnlyItems(searchResults);

          try {
            final windows = await _fetchContextWindows(
              pubkey: pubkey,
              groupId: groupId,
              results: searchResults,
              isCancelled: () => cancelled,
            );
            if (cancelled) return;
            displayItems.value = buildSearchDisplayList(
              results: searchResults,
              contextWindows: windows,
            );
          } catch (e, st) {
            if (!cancelled) {
              _logger.warning('context fetch failed, showing matches only', e, st);
            }
          }

          if (!cancelled) isSearching.value = false;
        })
        .catchError((Object e, StackTrace st) {
          if (!cancelled) {
            _logger.severe('search failed queryLength=${debouncedQuery.length}', e, st);
            results.value = [];
            displayItems.value = [];
            isSearching.value = false;
          }
        });

    return () => cancelled = true;
  }, [debouncedQuery, pubkey, groupId]);

  return (
    results: results.value,
    displayItems: displayItems.value,
    isSearching: isSearching.value,
  );
}

List<SearchDisplayItem> _matchOnlyItems(List<SearchResult> results) {
  final items = <SearchDisplayItem>[];
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
  return items;
}

Future<List<List<ChatMessage>>> _fetchContextWindows({
  required String pubkey,
  required String groupId,
  required List<SearchResult> results,
  required bool Function() isCancelled,
}) async {
  final windows = <List<ChatMessage>>[];

  for (final result in results) {
    if (isCancelled()) return windows;

    final match = result.message;

    final beforeMessages = await fetchAggregatedMessagesForGroup(
      pubkey: pubkey,
      groupId: groupId,
      before: match.createdAt,
      beforeMessageId: match.id,
      limit: searchContextSize,
    );

    if (isCancelled()) return windows;

    windows.add([...beforeMessages, match]);
  }

  return windows;
}

String _useDebouncedValue(String value, int milliseconds) {
  final debounced = useState('');

  useEffect(() {
    final timer = Timer(Duration(milliseconds: milliseconds), () {
      debounced.value = value;
    });
    return timer.cancel;
  }, [value, milliseconds]);

  return debounced.value;
}
