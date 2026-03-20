import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/services/user_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/user_search.dart' as user_search_api;
import 'package:whitenoise/src/rust/api/users.dart' show User;
import 'package:whitenoise/utils/encoding.dart';
import 'package:whitenoise/utils/logging.dart';
import 'package:whitenoise/utils/metadata.dart' show presentName;

final _logger = Logger('useUserSearch');

const _nameSearchDebounceMs = 400;
const _nameSearchBatchMs = 300;
const _nameSearchRadiusRounds = [(0, 2), (3, 3), (4, 4)];
const _followsRefreshInterval = Duration(seconds: 5);

bool _isPartialNpubQuery(String searchQuery, String? hexPubkeyFromQuery) {
  final trimmedSearchQuery = searchQuery.trim().toLowerCase();
  if (trimmedSearchQuery.isEmpty) return false;
  return 'npub1'.startsWith(trimmedSearchQuery) ||
      (trimmedSearchQuery.startsWith('npub1') && hexPubkeyFromQuery == null);
}

bool _isNameSearch(String searchQuery, String? hexPubkeyFromQuery) {
  final trimmed = searchQuery.trim();
  if (trimmed.isEmpty) return false;
  if (hexPubkeyFromQuery != null) return false;
  if (_isPartialNpubQuery(searchQuery, hexPubkeyFromQuery)) return false;
  return true;
}

bool _matchesNameQuery(User user, String query) {
  final q = query.toLowerCase();
  final meta = user.metadata;
  return (meta.name?.toLowerCase().contains(q) ?? false) ||
      (meta.displayName?.toLowerCase().contains(q) ?? false) ||
      (meta.nip05?.toLowerCase().contains(q) ?? false);
}

int _matchQualityRank(user_search_api.MatchQuality quality) {
  return switch (quality) {
    user_search_api.MatchQuality.exact => 0,
    user_search_api.MatchQuality.prefix => 1,
    user_search_api.MatchQuality.contains => 2,
  };
}

List<User> _sortByName(List<User> users) {
  return users.toList()..sort((a, b) {
    final nameA = presentName(a.metadata);
    final nameB = presentName(b.metadata);
    if (nameA != null && nameB != null) return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    if (nameA != null) return -1;
    if (nameB != null) return 1;
    return 0;
  });
}

User _userFromSearchResult(user_search_api.UserSearchResult result) {
  final now = DateTime.now();
  return User(
    pubkey: result.pubkey,
    metadata: result.metadata,
    createdAt: now,
    updatedAt: now,
  );
}

typedef UserSearchState = ({
  List<User> users,
  bool isLoading,
  bool isSearching,
  bool hasSearchQuery,
});

UserSearchState useUserSearch({
  required String accountPubkey,
  required String searchQuery,
}) {
  final followsRef = useRef(<User>[]);
  final trimmedSearchQuery = searchQuery.trim().toLowerCase();
  final hexPubkeyFromQuery = hexFromNpub(trimmedSearchQuery);
  final refreshTick = _usePeriodicTick(_followsRefreshInterval);

  final followsFuture = useMemoized(
    () async {
      final stopWatch = Stopwatch()..start();
      try {
        final follows = await accounts_api.accountFollows(pubkey: accountPubkey);
        return follows;
      } finally {
        logDuration(
          _logger,
          'accountFollows for $accountPubkey took',
          stopWatch.elapsedMilliseconds,
        );
      }
    },
    [accountPubkey, refreshTick],
  );
  final followsSnapshot = useFuture(followsFuture);
  final isLoadingFollows =
      followsSnapshot.connectionState == ConnectionState.waiting && followsRef.value.isEmpty;

  if (followsSnapshot.hasData) {
    followsRef.value = _sortByName(followsSnapshot.data!);
  }

  final follows = followsRef.value;

  final followNpubs = useMemoized(() {
    final Map<String, String?> npubMap = {};
    for (final user in follows) {
      npubMap[user.pubkey] = npubFromHex(user.pubkey);
    }
    return npubMap;
  }, [follows]);

  final searchStream = useMemoized(
    () => hexPubkeyFromQuery != null ? UserService(hexPubkeyFromQuery).watchUser() : null,
    [hexPubkeyFromQuery],
  );
  final searchSnapshot = useStream(searchStream);
  final isLoadingSearch = searchSnapshot.connectionState == ConnectionState.waiting;

  final hasSearchQuery = trimmedSearchQuery.isNotEmpty;
  final isPartialNpubSearch = _isPartialNpubQuery(searchQuery, hexPubkeyFromQuery);
  final isNameQuery = _isNameSearch(searchQuery, hexPubkeyFromQuery);

  final matchingFollows = useMemoized(() {
    if (!isPartialNpubSearch || follows.isEmpty) return follows;
    return follows.where((user) {
      final npub = followNpubs[user.pubkey];
      return npub != null && npub.startsWith(trimmedSearchQuery);
    }).toList();
  }, [trimmedSearchQuery, followNpubs, isPartialNpubSearch]);

  final localNameMatches = useMemoized(() {
    if (!isNameQuery || follows.isEmpty) return <User>[];
    return follows.where((user) => _matchesNameQuery(user, trimmedSearchQuery)).toList();
  }, [trimmedSearchQuery, follows, isNameQuery]);

  final nameSearchResults = useState(<User>[]);
  final isLoadingNameSearch = useState(false);
  final isSearchingNames = useState(false);
  final debouncedQuery = _useDebouncedValue(trimmedSearchQuery, _nameSearchDebounceMs);

  useEffect(() {
    if (!_isNameSearch(debouncedQuery, hexFromNpub(debouncedQuery))) {
      nameSearchResults.value = [];
      isLoadingNameSearch.value = false;
      isSearchingNames.value = false;
      return null;
    }

    isLoadingNameSearch.value = true;
    isSearchingNames.value = true;
    final results = <String, user_search_api.UserSearchResult>{};
    var hasPendingFlush = false;
    var cancelled = false;
    Timer? batchTimer;
    StreamSubscription<user_search_api.UserSearchUpdate>? activeSubscription;

    void flushResults() {
      final sorted = results.values.toList()
        ..sort(
          (a, b) => _matchQualityRank(a.matchQuality).compareTo(_matchQualityRank(b.matchQuality)),
        );
      nameSearchResults.value = sorted.map(_userFromSearchResult).toList();
      isLoadingNameSearch.value = false;
      hasPendingFlush = false;
    }

    void completeRound(Completer<void> completer) {
      batchTimer?.cancel();
      flushResults();
      activeSubscription?.cancel();
      if (!completer.isCompleted) completer.complete();
    }

    Future<void> runRounds() async {
      for (final (radiusStart, radiusEnd) in _nameSearchRadiusRounds) {
        if (cancelled) return;

        final completer = Completer<void>();

        activeSubscription = user_search_api
            .searchUsers(
              accountPubkey: accountPubkey,
              query: debouncedQuery,
              radiusStart: radiusStart,
              radiusEnd: radiusEnd,
            )
            .listen(
              (update) {
                for (final result in update.newResults) {
                  final existing = results[result.pubkey];
                  if (existing == null ||
                      _matchQualityRank(result.matchQuality) <
                          _matchQualityRank(existing.matchQuality)) {
                    results[result.pubkey] = result;
                  }
                }

                final isComplete =
                    update.trigger is user_search_api.SearchUpdateTrigger_SearchCompleted;
                if (isComplete) {
                  completeRound(completer);
                } else if (!hasPendingFlush) {
                  hasPendingFlush = true;
                  batchTimer = Timer(
                    const Duration(milliseconds: _nameSearchBatchMs),
                    flushResults,
                  );
                }
              },
              onDone: () => completeRound(completer),
              onError: (Object error, StackTrace stack) {
                _logger.severe('Name search failed for "$debouncedQuery"', error, stack);
                batchTimer?.cancel();
                activeSubscription?.cancel();
                isLoadingNameSearch.value = false;
                isSearchingNames.value = false;
                if (!completer.isCompleted) completer.complete();
                cancelled = true;
              },
            );

        await completer.future;
      }

      if (!cancelled) {
        isSearchingNames.value = false;
      }
    }

    runRounds();

    return () {
      cancelled = true;
      batchTimer?.cancel();
      activeSubscription?.cancel();
    };
  }, [debouncedQuery, accountPubkey]);

  final List<User> users;
  final bool isLoading;

  if (!hasSearchQuery) {
    users = follows;
    isLoading = isLoadingFollows;
  } else if (hexPubkeyFromQuery != null) {
    isLoading = isLoadingSearch;
    final user = searchSnapshot.data;
    users = user != null ? [user] : [];
  } else if (isPartialNpubSearch) {
    users = matchingFollows;
    isLoading = isLoadingFollows;
  } else {
    final bfsResults = nameSearchResults.value;
    final bfsPubkeys = bfsResults.map((u) => u.pubkey).toSet();
    final uniqueLocalMatches = localNameMatches.where((u) => !bfsPubkeys.contains(u.pubkey));
    users = [...bfsResults, ...uniqueLocalMatches];
    isLoading = isLoadingNameSearch.value && bfsResults.isEmpty && localNameMatches.isEmpty;
  }

  final filteredUsers = users.where((user) => user.pubkey != accountPubkey).toList();

  return (
    users: filteredUsers,
    isLoading: isLoading,
    isSearching: isNameQuery && isSearchingNames.value,
    hasSearchQuery: hasSearchQuery,
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

int _usePeriodicTick(Duration interval) {
  final tick = useState(0);

  useEffect(() {
    final timer = Timer.periodic(interval, (_) {
      tick.value++;
    });
    return timer.cancel;
  }, [interval]);

  return tick.value;
}
