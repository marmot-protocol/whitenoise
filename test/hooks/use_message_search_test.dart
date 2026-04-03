import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_message_search.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

ChatMessage _messageFactory(String id, String content) => ChatMessage(
  id: id,
  pubkey: testPubkeyA,
  content: content,
  createdAt: DateTime(2024),
  tags: const [],
  isReply: false,
  isDeleted: false,
  contentTokens: const [],
  reactions: const ReactionSummary(byEmoji: [], userReactions: []),
  mediaAttachments: const [],
  kind: 1,
);

SearchResult _searchResultFactory(
  String id,
  String content, {
  List<HighlightSpan> spans = const [],
  int position = 0,
}) => SearchResult(
  message: _messageFactory(id, content),
  highlightSpans: spans,
  position: BigInt.from(position),
);

class _MockApi extends MockWnApi {
  List<SearchResult> searchResults = [];
  bool shouldFailSearch = false;
  bool shouldFailContextFetch = false;
  Completer<List<SearchResult>>? searchCompleter;
  Completer<List<ChatMessage>>? contextFetchCompleter;
  final searchCalls = <({String pubkey, String groupId, String query})>[];

  @override
  Future<List<SearchResult>> crateApiMessagesSearchMessagesInGroup({
    required String pubkey,
    required String groupId,
    required String query,
    int? limit,
  }) {
    searchCalls.add((pubkey: pubkey, groupId: groupId, query: query));
    if (searchCompleter != null) return searchCompleter!.future;
    if (shouldFailSearch) return Future.error(Exception('search failed'));
    return Future.value(searchResults);
  }

  @override
  Future<List<ChatMessage>> crateApiMessagesFetchAggregatedMessagesForGroup({
    required String pubkey,
    required String groupId,
    DateTime? before,
    String? beforeMessageId,
    int? limit,
  }) {
    if (shouldFailContextFetch) return Future.error(Exception('context fetch failed'));
    if (contextFetchCompleter != null) return contextFetchCompleter!.future;
    return Future.value([]);
  }

  @override
  void reset() {
    super.reset();
    searchResults = [];
    shouldFailSearch = false;
    shouldFailContextFetch = false;
    searchCompleter = null;
    contextFetchCompleter = null;
    searchCalls.clear();
  }
}

void main() {
  final api = _MockApi();
  late MessageSearchResult Function() getState;

  setUpAll(() => RustLib.initMock(api: api));

  setUp(() {
    api.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    String pubkey = testPubkeyA,
    String groupId = testGroupId,
    String query = '',
  }) async {
    getState = await mountHook(
      tester,
      () => useMessageSearch(pubkey: pubkey, groupId: groupId, query: query),
    );
  }

  group('useMessageSearch', () {
    group('with empty query', () {
      testWidgets('returns empty results and is not searching', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(getState().results, isEmpty);
        expect(getState().isSearching, isFalse);
      });

      testWidgets('does not call the search API', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(api.searchCalls, isEmpty);
      });
    });

    group('with non-empty query', () {
      testWidgets('calls search API with correct parameters after debounce', (tester) async {
        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(api.searchCalls.length, 1);
        expect(api.searchCalls[0].pubkey, testPubkeyA);
        expect(api.searchCalls[0].groupId, testGroupId);
        expect(api.searchCalls[0].query, 'hello');
      });

      testWidgets('does not call API before debounce period elapses', (tester) async {
        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 100));

        expect(api.searchCalls, isEmpty);
      });

      testWidgets('returns results after search completes', (tester) async {
        api.searchResults = [
          _searchResultFactory('msg1', 'hello world'),
          _searchResultFactory('msg2', 'say hello'),
        ];

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pump();

        expect(getState().results.length, 2);
        expect(getState().results[0].message.id, 'msg1');
        expect(getState().results[1].message.id, 'msg2');
        expect(getState().isSearching, isFalse);
      });

      testWidgets('populates displayItems with match items', (tester) async {
        api.searchResults = [
          _searchResultFactory('msg1', 'hello world'),
        ];

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pump();

        final items = getState().displayItems;
        expect(items, isNotEmpty);
        expect(items.where((i) => i.isMatch).length, 1);
        expect(items.first.message!.id, 'msg1');
      });

      testWidgets('isSearching is true while search is in flight', (tester) async {
        api.searchCompleter = Completer();

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));

        expect(getState().isSearching, isTrue);
      });

      testWidgets('clears results and stops searching when query becomes empty', (tester) async {
        api.searchResults = [_searchResultFactory('msg1', 'hello')];

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pump();
        expect(getState().results.length, 1);

        // Re-mount with empty query — results should be cleared immediately
        await pump(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(getState().results, isEmpty);
        expect(getState().displayItems, isEmpty);
        expect(getState().isSearching, isFalse);
      });

      testWidgets('returns empty results on search error', (tester) async {
        api.shouldFailSearch = true;

        // Must pump past the debounce so the search is triggered
        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(getState().results, isEmpty);
        expect(getState().isSearching, isFalse);
      });

      testWidgets('falls back to match-only items when context fetch fails', (tester) async {
        api.shouldFailContextFetch = true;
        api.searchResults = [
          _searchResultFactory('msg1', 'hello world'),
          _searchResultFactory('msg2', 'say hello'),
        ];

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pump();

        final items = getState().displayItems;
        expect(items, isNotEmpty);
        final matches = items.where((i) => i.isMatch).toList();
        expect(matches.length, 2);
        expect(matches[0].message!.id, 'msg1');
        expect(matches[1].message!.id, 'msg2');
        expect(getState().isSearching, isFalse);
      });

      testWidgets('result includes highlight spans', (tester) async {
        api.searchResults = [
          _searchResultFactory(
            'msg1',
            'hello world',
            spans: [const HighlightSpan(start: 0, end: 5)],
          ),
        ];

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(getState().results[0].highlightSpans.length, 1);
        expect(getState().results[0].highlightSpans[0].start, 0);
        expect(getState().results[0].highlightSpans[0].end, 5);
      });

      testWidgets('stale context fetch does not overwrite new query results', (tester) async {
        api.searchResults = [_searchResultFactory('msg1', 'hello world')];
        api.contextFetchCompleter = Completer();

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(getState().results.length, 1);
        expect(getState().displayItems.where((i) => i.isMatch).length, 1);

        api.searchResults = [_searchResultFactory('msg2', 'new result')];
        api.contextFetchCompleter = null;

        await pump(tester, query: 'new');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        await tester.pump();

        expect(getState().results.length, 1);
        expect(getState().results[0].message.id, 'msg2');
      });
    });
  });
}
