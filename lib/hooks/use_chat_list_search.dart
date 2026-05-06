import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

final _logger = Logger('useChatListSearch');

const _searchDebounceMs = 150;

typedef ChatListSearchResult = ({
  Map<String, String> messageSnippets,
  Set<String> matchedGroupIds,
  bool isSearching,
});

ChatListSearchResult useChatListSearch({
  required String pubkey,
  required String query,
  Set<String> hiddenPubkeys = const {},
}) {
  final messageSnippets = useState<Map<String, String>>({});
  final matchedGroupIds = useState<Set<String>>({});
  final isSearching = useState(false);
  final debouncedQuery = _useDebouncedValue(query, _searchDebounceMs);
  final trimmedQuery = debouncedQuery.trim();
  final hiddenPubkeysKey = useMemoized(
    () {
      final sorted = hiddenPubkeys.toList()..sort();
      return sorted.join('|');
    },
    [hiddenPubkeys],
  );

  useEffect(() {
    if (trimmedQuery.isEmpty) {
      messageSnippets.value = {};
      matchedGroupIds.value = {};
      isSearching.value = false;
      return null;
    }

    isSearching.value = true;
    var cancelled = false;

    searchMessages(pubkey: pubkey, query: trimmedQuery)
        .then((results) {
          if (cancelled) return;
          final visibleResults = results
              .where((result) => !hiddenPubkeys.contains(result.message.pubkey))
              .toList();
          _logger.info(
            'cross-group search completed '
            'queryLength=${trimmedQuery.length} results=${visibleResults.length}',
          );

          final snippets = <String, String>{};
          final groupIds = <String>{};
          for (final result in visibleResults) {
            groupIds.add(result.mlsGroupId);
            snippets.putIfAbsent(result.mlsGroupId, () => result.message.content);
          }

          messageSnippets.value = snippets;
          matchedGroupIds.value = groupIds;
          isSearching.value = false;
        })
        .catchError((Object e, StackTrace st) {
          if (!cancelled) {
            _logger.severe(
              'cross-group search failed queryLength=${trimmedQuery.length}',
              e,
              st,
            );
            messageSnippets.value = {};
            matchedGroupIds.value = {};
            isSearching.value = false;
          }
        });

    return () => cancelled = true;
  }, [trimmedQuery, pubkey, hiddenPubkeysKey]);

  return (
    messageSnippets: messageSnippets.value,
    matchedGroupIds: matchedGroupIds.value,
    isSearching: isSearching.value,
  );
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
