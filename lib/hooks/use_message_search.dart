import 'dart:async';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

final _logger = Logger('useMessageSearch');

const _searchDebounceMs = 300;

typedef MessageSearchResult = ({
  List<ChatMessage> results,
  bool isSearching,
});

MessageSearchResult useMessageSearch({
  required String pubkey,
  required String groupId,
  required String query,
}) {
  final results = useState<List<ChatMessage>>([]);
  final isSearching = useState(false);
  final debouncedQuery = _useDebouncedValue(query, _searchDebounceMs);

  useEffect(() {
    if (debouncedQuery.isEmpty) {
      results.value = [];
      isSearching.value = false;
      return null;
    }

    isSearching.value = true;
    var cancelled = false;

    searchMessagesInGroup(
      pubkey: pubkey,
      groupId: groupId,
      query: debouncedQuery,
    ).then((messages) {
      if (!cancelled) {
        _logger.info(
          'search completed groupId=${groupId.substring(0, 8)}… '
          'query="$debouncedQuery" results=${messages.length}',
        );
        results.value = messages;
        isSearching.value = false;
      }
    }).catchError((Object e, StackTrace st) {
      if (!cancelled) {
        _logger.severe('search failed query="$debouncedQuery"', e, st);
        results.value = [];
        isSearching.value = false;
      }
    });

    return () => cancelled = true;
  }, [debouncedQuery, pubkey, groupId]);

  return (results: results.value, isSearching: isSearching.value);
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
