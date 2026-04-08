import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_chat_list_search.dart';
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
  String groupId = testGroupId,
  List<HighlightSpan> spans = const [],
  int position = 0,
}) => SearchResult(
  message: _messageFactory(id, content),
  mlsGroupId: groupId,
  highlightSpans: spans,
  position: BigInt.from(position),
);

class _MockApi extends MockWnApi {
  List<SearchResult> searchResults = [];
  bool shouldFailSearch = false;
  Completer<List<SearchResult>>? searchCompleter;
  final searchCalls = <({String pubkey, String query})>[];

  @override
  Future<List<SearchResult>> crateApiMessagesSearchMessages({
    required String pubkey,
    required String query,
    int? limit,
  }) {
    searchCalls.add((pubkey: pubkey, query: query));
    if (searchCompleter != null) return searchCompleter!.future;
    if (shouldFailSearch) return Future.error(Exception('search failed'));
    return Future.value(searchResults);
  }

  @override
  void reset() {
    super.reset();
    searchResults = [];
    shouldFailSearch = false;
    searchCompleter = null;
    searchCalls.clear();
  }
}

void main() {
  final api = _MockApi();
  late ChatListSearchResult Function() getState;

  setUpAll(() => RustLib.initMock(api: api));

  setUp(() {
    api.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    String pubkey = testPubkeyA,
    String query = '',
  }) async {
    getState = await mountHook(
      tester,
      () => useChatListSearch(pubkey: pubkey, query: query),
    );
  }

  group('useChatListSearch', () {
    group('with empty query', () {
      testWidgets('returns empty results and is not searching', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(getState().messageSnippets, isEmpty);
        expect(getState().matchedGroupIds, isEmpty);
        expect(getState().isSearching, isFalse);
      });

      testWidgets('does not call the search API', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(api.searchCalls, isEmpty);
      });

      testWidgets('treats whitespace-only query as empty', (tester) async {
        await pump(tester, query: '   ');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(api.searchCalls, isEmpty);
        expect(getState().messageSnippets, isEmpty);
        expect(getState().matchedGroupIds, isEmpty);
        expect(getState().isSearching, isFalse);
      });
    });

    group('debounce behavior', () {
      testWidgets('does not call API before debounce period elapses', (tester) async {
        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 100));

        expect(api.searchCalls, isEmpty);
      });

      testWidgets('calls search API after 150ms debounce', (tester) async {
        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(api.searchCalls.length, 1);
        expect(api.searchCalls[0].pubkey, testPubkeyA);
        expect(api.searchCalls[0].query, 'hello');
      });
    });

    group('with non-empty query', () {
      testWidgets('returns message snippets and matched group IDs on success', (tester) async {
        api.searchResults = [
          _searchResultFactory('msg1', 'hello world'),
          _searchResultFactory(
            'msg2',
            'say hello',
            groupId: otherTestGroupId,
          ),
        ];

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(getState().matchedGroupIds, {testGroupId, otherTestGroupId});
        expect(getState().messageSnippets[testGroupId], 'hello world');
        expect(getState().messageSnippets[otherTestGroupId], 'say hello');
        expect(getState().isSearching, isFalse);
      });

      testWidgets('groups results by mlsGroupId keeping first match per group', (tester) async {
        api.searchResults = [
          _searchResultFactory('msg1', 'first match'),
          _searchResultFactory('msg2', 'second match'),
        ];

        await pump(tester, query: 'match');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(getState().messageSnippets[testGroupId], 'first match');
        expect(getState().matchedGroupIds, {testGroupId});
      });

      testWidgets('isSearching is true while search is in flight', (tester) async {
        api.searchCompleter = Completer();

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 150));

        expect(getState().isSearching, isTrue);
      });

      testWidgets('clears results when query is cleared', (tester) async {
        api.searchResults = [
          _searchResultFactory('msg1', 'hello'),
        ];

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
        expect(getState().matchedGroupIds, isNotEmpty);

        await pump(tester);
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        expect(getState().messageSnippets, isEmpty);
        expect(getState().matchedGroupIds, isEmpty);
        expect(getState().isSearching, isFalse);
      });

      testWidgets('handles search errors gracefully', (tester) async {
        api.shouldFailSearch = true;

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        expect(getState().messageSnippets, isEmpty);
        expect(getState().matchedGroupIds, isEmpty);
        expect(getState().isSearching, isFalse);
      });

      testWidgets('cancels stale requests when query changes', (tester) async {
        api.searchCompleter = Completer();

        await pump(tester, query: 'hello');
        await tester.pump(const Duration(milliseconds: 150));
        expect(getState().isSearching, isTrue);

        final staleCompleter = api.searchCompleter!;

        api.searchCompleter = null;
        api.searchResults = [
          _searchResultFactory('msg2', 'new result', groupId: otherTestGroupId),
        ];

        await pump(tester, query: 'new');
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();

        staleCompleter.complete([
          _searchResultFactory('msg1', 'stale'),
        ]);
        await tester.pump();

        expect(getState().matchedGroupIds, {otherTestGroupId});
        expect(getState().messageSnippets[otherTestGroupId], 'new result');
        expect(getState().messageSnippets.containsKey(testGroupId), isFalse);
      });
    });
  });
}
