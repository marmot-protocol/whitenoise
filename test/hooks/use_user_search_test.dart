import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/hooks/use_user_search.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';
import 'package:whitenoise/src/rust/api/user_search.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import '../mocks/mock_wn_api.dart';
import '../test_helpers.dart';

User _userFactory(
  String pubkey, {
  String? name,
  String? displayName,
  String? picture,
}) => User(
  pubkey: pubkey,
  metadata: FlutterMetadata(
    name: name,
    displayName: displayName,
    picture: picture,
    custom: const {},
  ),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

UserSearchResult _searchResultFactory(
  String pubkey, {
  String? displayName,
  MatchQuality matchQuality = MatchQuality.exact,
  MatchedField bestField = MatchedField.name,
}) => UserSearchResult(
  pubkey: pubkey,
  metadata: FlutterMetadata(displayName: displayName, custom: const {}),
  radius: 0,
  matchQuality: matchQuality,
  bestField: bestField,
  matchedFields: [bestField],
);

class _MockApi extends MockWnApi {
  Completer<List<User>>? followsCompleter;
  final Map<String, User> userByPubkey = {};
  final Map<String, User> blockingUserByPubkey = {};
  final Map<String, String> npubToPubkey = {};
  final Set<String> errorPubkeys = {};
  Completer<User>? userCompleter;
  final userCalls = <({String pubkey, bool blocking})>[];
  final followsCalls = <String>[];
  final searchUsersCalls = <({String query, String accountPubkey})>[];

  @override
  Future<List<User>> crateApiAccountsAccountFollows({required String pubkey}) {
    followsCalls.add(pubkey);
    if (followsCompleter != null) return followsCompleter!.future;
    return Future.value(follows);
  }

  @override
  Future<User> crateApiUsersGetUser({
    required String pubkey,
    required bool blockingDataSync,
  }) {
    userCalls.add((pubkey: pubkey, blocking: blockingDataSync));
    if (userCompleter != null) return userCompleter!.future;
    if (errorPubkeys.contains(pubkey)) throw Exception('User not found');
    final user = blockingDataSync
        ? (blockingUserByPubkey[pubkey] ?? userByPubkey[pubkey])
        : userByPubkey[pubkey];
    if (user == null) throw Exception('User not found');
    return Future.value(user);
  }

  @override
  String crateApiUtilsHexPubkeyFromNpub({required String npub}) {
    final pubkey = npubToPubkey[npub];
    if (pubkey == null) throw Exception('Invalid npub');
    return pubkey;
  }

  @override
  Stream<UserSearchUpdate> crateApiUserSearchSearchUsers({
    required String accountPubkey,
    required String query,
    required int radiusStart,
    required int radiusEnd,
  }) {
    searchUsersCalls.add((query: query, accountPubkey: accountPubkey));
    return super.crateApiUserSearchSearchUsers(
      accountPubkey: accountPubkey,
      query: query,
      radiusStart: radiusStart,
      radiusEnd: radiusEnd,
    );
  }

  @override
  void reset() {
    super.reset();
    followsCompleter = null;
    userByPubkey.clear();
    blockingUserByPubkey.clear();
    npubToPubkey.clear();
    errorPubkeys.clear();
    userCompleter = null;
    userCalls.clear();
    followsCalls.clear();
    searchUsersCalls.clear();
  }
}

void main() {
  final api = _MockApi();
  late UserSearchState Function() getState;

  setUpAll(() => RustLib.initMock(api: api));

  setUp(() {
    api.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    String accountPubkey = 'test_account',
    String searchQuery = '',
  }) async {
    getState = await mountHook(
      tester,
      () => useUserSearch(
        accountPubkey: accountPubkey,
        searchQuery: searchQuery,
      ),
    );
  }

  group('useUserSearch', () {
    group('when follows are loading', () {
      testWidgets('isLoading is true and users is empty', (tester) async {
        api.followsCompleter = Completer();
        await pump(tester);

        expect(getState().isLoading, isTrue);
        expect(getState().users, isEmpty);
      });
    });

    group('without follows', () {
      testWidgets('returns empty list', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(getState().users, isEmpty);
        expect(getState().isLoading, isFalse);
        expect(getState().hasSearchQuery, isFalse);
      });
    });

    group('with follows', () {
      setUp(() {
        api.follows = [
          _userFactory(testPubkeyA, displayName: 'Alice'),
          _userFactory(testPubkeyB, displayName: 'Bob'),
        ];
      });

      testWidgets('returns users list', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(getState().users.length, 2);
        expect(getState().users[0].pubkey, testPubkeyA);
        expect(getState().users[1].pubkey, testPubkeyB);
      });

      testWidgets('calls follows API with correct accountPubkey', (tester) async {
        await pump(tester, accountPubkey: 'my_account');
        await tester.pump();

        expect(api.followsCalls.length, 1);
        expect(api.followsCalls[0], 'my_account');
      });
    });

    group('npub search', () {
      group('when query is empty', () {
        testWidgets('hasSearchQuery is false', (tester) async {
          await pump(tester);
          await tester.pump();

          expect(getState().hasSearchQuery, isFalse);
        });
      });

      group('when query is valid npub', () {
        setUp(() {
          api.npubToPubkey[testNpubC] = testPubkeyC;
          api.userByPubkey[testPubkeyC] = _userFactory(testPubkeyC, displayName: 'Found User');
        });

        testWidgets('returns searched user in users list', (tester) async {
          await pump(tester, searchQuery: testNpubC);
          await tester.pump();

          expect(getState().users.length, 1);
          expect(getState().users[0].pubkey, testPubkeyC);
          expect(getState().users[0].metadata.displayName, 'Found User');
        });

        testWidgets('isLoading is true while fetching', (tester) async {
          api.userCompleter = Completer();
          await pump(tester, searchQuery: testNpubC);

          expect(getState().isLoading, isTrue);
        });

        testWidgets('does not retry with blocking when metadata is complete', (tester) async {
          await pump(tester, searchQuery: testNpubC);
          await tester.pump();

          expect(api.userCalls.length, 1);
          expect(api.userCalls[0].blocking, isFalse);
        });

        testWidgets('retries with blocking when metadata is incomplete', (tester) async {
          api.userByPubkey[testPubkeyC] = _userFactory(testPubkeyC);
          api.blockingUserByPubkey[testPubkeyC] = _userFactory(
            testPubkeyC,
            displayName: 'Synced User',
          );

          await pump(tester, searchQuery: testNpubC);
          await tester.pump();

          expect(api.userCalls.length, 2);
          expect(api.userCalls[0].blocking, isFalse);
          expect(api.userCalls[1].blocking, isTrue);
          expect(getState().users[0].metadata.displayName, 'Synced User');
        });

        testWidgets('returns empty list when getUser throws', (tester) async {
          api.errorPubkeys.add(testPubkeyC);

          await pump(tester, searchQuery: testNpubC);
          await tester.pump();

          expect(getState().users, isEmpty);
          expect(getState().isLoading, isFalse);
        });
      });
    });

    group('partial npub search', () {
      setUp(() {
        api.follows = [
          _userFactory(testPubkeyA, displayName: 'Alice'),
          _userFactory(testPubkeyB, displayName: 'Bob'),
          _userFactory(testPubkeyC, displayName: 'Charlie'),
        ];
      });

      testWidgets('returns all follows for partial npub1 prefix queries', (tester) async {
        await pump(tester, searchQuery: 'n');
        await tester.pump();
        expect(getState().users.length, 3);
        await pump(tester, searchQuery: 'np');
        await tester.pump();
        expect(getState().users.length, 3);
        await pump(tester, searchQuery: 'npu');
        await tester.pump();
        expect(getState().users.length, 3);
        await pump(tester, searchQuery: 'npub');
        await tester.pump();
        expect(getState().users.length, 3);
        await pump(tester, searchQuery: 'npub1');
        await tester.pump();
        expect(getState().users.length, 3);
      });

      testWidgets('filters follows by npub prefix', (tester) async {
        await pump(tester, searchQuery: 'npub1a1b');
        await tester.pump();

        expect(getState().users.length, 1);
        expect(getState().users[0].pubkey, testPubkeyA);
      });

      testWidgets('filters follows case-insensitively', (tester) async {
        await pump(tester, searchQuery: 'NPUB1A1B');
        await tester.pump();

        expect(getState().users.length, 1);
      });

      testWidgets('returns empty list when no matches', (tester) async {
        await pump(tester, searchQuery: 'npub1xyz');
        await tester.pump();

        expect(getState().users, isEmpty);
        expect(getState().hasSearchQuery, isTrue);
      });

      testWidgets('returns all follows when query is empty', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(getState().users.length, 3);
      });

      testWidgets('excludes follows with invalid pubkeys', (tester) async {
        api.follows = [
          _userFactory(testPubkeyA, displayName: 'Alice'),
          _userFactory('invalid_pub', displayName: 'Bob'),
        ];

        await pump(tester, searchQuery: 'npub1a1b');
        await tester.pump();

        expect(getState().users.length, 1);
        expect(getState().users[0].pubkey, testPubkeyA);
      });
    });

    group('sorting', () {
      testWidgets('sorts users with metadata before users without', (tester) async {
        api.follows = [
          _userFactory(testPubkeyA),
          _userFactory(testPubkeyB, displayName: 'Bob'),
          _userFactory(testPubkeyC, displayName: 'Alice'),
        ];
        await pump(tester);
        await tester.pump();

        expect(getState().users[0].pubkey, testPubkeyC);
        expect(getState().users[1].pubkey, testPubkeyB);
        expect(getState().users[2].pubkey, testPubkeyA);
      });

      testWidgets('sorts users with metadata alphabetically', (tester) async {
        api.follows = [
          _userFactory(testPubkeyA, displayName: 'Charlie'),
          _userFactory(testPubkeyB, displayName: 'Alice'),
          _userFactory(testPubkeyC, displayName: 'Bob'),
        ];
        await pump(tester);
        await tester.pump();

        expect(getState().users[0].metadata.displayName, 'Alice');
        expect(getState().users[1].metadata.displayName, 'Bob');
        expect(getState().users[2].metadata.displayName, 'Charlie');
      });

      testWidgets('alphabetical sort is case-insensitive', (tester) async {
        api.follows = [
          _userFactory(testPubkeyA, displayName: 'bob'),
          _userFactory(testPubkeyB, displayName: 'Alice'),
        ];
        await pump(tester);
        await tester.pump();

        expect(getState().users[0].metadata.displayName, 'Alice');
        expect(getState().users[1].metadata.displayName, 'bob');
      });

      testWidgets('preserves sort after periodic refresh', (tester) async {
        api.follows = [
          _userFactory(testPubkeyA),
          _userFactory(testPubkeyB, displayName: 'Zara'),
        ];
        await pump(tester);
        await tester.pump();

        expect(getState().users[0].pubkey, testPubkeyB);
        expect(getState().users[1].pubkey, testPubkeyA);

        api.follows = [
          _userFactory(testPubkeyA, displayName: 'Alice'),
          _userFactory(testPubkeyB, displayName: 'Zara'),
        ];
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();

        expect(getState().users[0].metadata.displayName, 'Alice');
        expect(getState().users[1].metadata.displayName, 'Zara');
      });
    });

    group('name search', () {
      testWidgets('triggers name search for non-npub query after debounce', (tester) async {
        await pump(tester, searchQuery: 'alice');
        expect(getState().hasSearchQuery, isTrue);

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(api.searchUsersCalls.length, 1);
        expect(api.searchUsersCalls[0].query, 'alice');
      });

      testWidgets('returns users from search results', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [_searchResultFactory(testPubkeyA, displayName: 'Alice')],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(getState().users.length, 1);
        expect(getState().users[0].pubkey, testPubkeyA);
        expect(getState().users[0].metadata.displayName, 'Alice');
        expect(getState().isLoading, isFalse);
      });

      testWidgets('sorts results by match quality', (tester) async {
        await pump(tester, searchQuery: 'bob');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [
              _searchResultFactory(
                testPubkeyB,
                displayName: 'Bobby',
                matchQuality: MatchQuality.contains,
              ),
              _searchResultFactory(
                testPubkeyA,
                displayName: 'Bob',
              ),
            ],
            totalResultCount: BigInt.two,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(getState().users.length, 2);
        expect(getState().users[0].pubkey, testPubkeyA);
        expect(getState().users[1].pubkey, testPubkeyB);
      });

      testWidgets('batches rapid updates into single rebuild', (tester) async {
        await pump(tester, searchQuery: 'test');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [_searchResultFactory(testPubkeyA, displayName: 'TestA')],
            totalResultCount: BigInt.one,
          ),
        );
        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [
              _searchResultFactory(
                testPubkeyB,
                displayName: 'TestB',
                matchQuality: MatchQuality.prefix,
              ),
            ],
            totalResultCount: BigInt.two,
          ),
        );
        await tester.pump();
        expect(getState().users, isEmpty);

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(getState().users.length, 2);
      });

      testWidgets('deduplicates results keeping best match quality', (tester) async {
        await pump(tester, searchQuery: 'test');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [
              _searchResultFactory(
                testPubkeyA,
                displayName: 'TestA',
                matchQuality: MatchQuality.contains,
              ),
            ],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [
              _searchResultFactory(
                testPubkeyA,
                displayName: 'TestA',
              ),
            ],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(getState().users.length, 1);
        expect(getState().users[0].pubkey, testPubkeyA);
      });

      testWidgets('shows empty results when search completes with no results', (tester) async {
        await pump(tester, searchQuery: 'zzzzz');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: SearchUpdateTrigger.searchCompleted(
              finalRadius: 2,
              totalResults: BigInt.zero,
            ),
            newResults: const [],
            totalResultCount: BigInt.zero,
          ),
        );
        await tester.pump();

        expect(getState().users, isEmpty);
        expect(getState().isLoading, isFalse);
        expect(getState().hasSearchQuery, isTrue);
      });

      testWidgets('isLoading is true before results arrive', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(getState().isLoading, isTrue);
        expect(getState().users, isEmpty);
      });

      testWidgets('isLoading becomes false after first batch flushes', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [_searchResultFactory(testPubkeyA, displayName: 'Alice')],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump();
        expect(getState().isLoading, isTrue);

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(getState().isLoading, isFalse);
      });

      testWidgets('clears results when query is cleared', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [_searchResultFactory(testPubkeyA, displayName: 'Alice')],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(getState().users.length, 1);

        await pump(tester);
        await tester.pump();

        expect(getState().hasSearchQuery, isFalse);
      });

      testWidgets('does not search before debounce period', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 100));

        expect(api.searchUsersCalls, isEmpty);
      });

      testWidgets('isSearching is true while stream is active', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(getState().isSearching, isTrue);

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [_searchResultFactory(testPubkeyA, displayName: 'Alice')],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(getState().isSearching, isTrue);
        expect(getState().users.length, 1);
      });

      testWidgets('isSearching becomes false when stream completes', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(getState().isSearching, isTrue);

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: SearchUpdateTrigger.searchCompleted(
              finalRadius: 2,
              totalResults: BigInt.one,
            ),
            newResults: [_searchResultFactory(testPubkeyA, displayName: 'Alice')],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump();

        expect(getState().isSearching, isFalse);
      });

      testWidgets('isSearching is false for non-name queries', (tester) async {
        await pump(tester);
        await tester.pump();

        expect(getState().isSearching, isFalse);
      });

      testWidgets('flushes results and stops searching when stream closes', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: const SearchUpdateTrigger.resultsFound(),
            newResults: [_searchResultFactory(testPubkeyA, displayName: 'Alice')],
            totalResultCount: BigInt.one,
          ),
        );
        await tester.pump();
        expect(getState().isSearching, isTrue);

        api.searchUsersController!.close();
        await tester.pump();

        expect(getState().users.length, 1);
        expect(getState().isSearching, isFalse);
        expect(getState().isLoading, isFalse);
      });

      testWidgets('stops searching on stream error', (tester) async {
        await pump(tester, searchQuery: 'alice');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        expect(getState().isSearching, isTrue);

        api.searchUsersController!.addError(Exception('network error'));
        await tester.pump();

        expect(getState().isSearching, isFalse);
        expect(getState().isLoading, isFalse);
      });

      testWidgets('returns local follow matches when BFS returns no results', (tester) async {
        api.follows = [
          _userFactory(testPubkeyA, displayName: 'Alice'),
          _userFactory(testPubkeyB, displayName: 'Bob'),
        ];

        await pump(tester, searchQuery: 'alice');
        await tester.pump(); // resolve follows future
        await tester.pump(const Duration(milliseconds: 400)); // debounce
        await tester.pump(); // trigger search

        // BFS search completes with zero results
        api.searchUsersController!.add(
          UserSearchUpdate(
            trigger: SearchUpdateTrigger.searchCompleted(
              finalRadius: 2,
              totalResults: BigInt.zero,
            ),
            newResults: const [],
            totalResultCount: BigInt.zero,
          ),
        );
        await tester.pump();

        // Local follow "Alice" should still appear
        expect(getState().users.length, 1);
        expect(getState().users[0].pubkey, testPubkeyA);
        expect(getState().users[0].metadata.displayName, 'Alice');
        expect(getState().isLoading, isFalse);
      });

      testWidgets('returns empty state for whitespace-only query', (tester) async {
        await pump(tester, searchQuery: '   ');
        await tester.pump();

        expect(getState().users, isEmpty);
        expect(getState().isLoading, isFalse);
        expect(getState().hasSearchQuery, isFalse);
      });
    });
  });
}
