import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/mute_list.dart' as mute_list_api;

final _logger = Logger('useBlockedPubkeys');

typedef BlockedPubkeysState = ({
  Set<String> blockedPubkeys,
  bool isLoading,
  String? error,
  VoidCallback refresh,
});

class _BlockedPubkeysCacheEntry {
  Set<String> blockedPubkeys = <String>{};
  bool hasLoaded = false;
}

final Map<String, _BlockedPubkeysCacheEntry> _blockedPubkeysCaches = {};

@visibleForTesting
void resetBlockedPubkeysCacheForTests() => _blockedPubkeysCaches.clear();

BlockedPubkeysState useBlockedPubkeys(String accountPubkey, {int refreshKey = 0}) {
  final cache = _blockedPubkeysCaches.putIfAbsent(
    accountPubkey,
    _BlockedPubkeysCacheEntry.new,
  );
  final blockedPubkeys = useState<Set<String>>(cache.blockedPubkeys);
  final isLoading = useState(!cache.hasLoaded);
  final error = useState<String?>(null);
  final manualRefreshKey = useState(0);

  useEffect(() {
    var cancelled = false;
    if (!cache.hasLoaded) isLoading.value = true;

    Future<void> fetchBlockedPubkeys() async {
      try {
        final entries = await mute_list_api.getBlockedUsers(accountPubkey: accountPubkey);
        if (cancelled) return;
        final next = entries.map((entry) => entry.mutedPubkey).toSet();
        cache.blockedPubkeys = next;
        cache.hasLoaded = true;
        blockedPubkeys.value = next;
        error.value = null;
      } catch (e, st) {
        if (cancelled) return;
        blockedPubkeys.value = {};
        _logger.severe('Failed to fetch blocked users', e, st);
        error.value = 'failedToFetchBlockedUsers';
      } finally {
        if (!cancelled) isLoading.value = false;
      }
    }

    fetchBlockedPubkeys();
    return () => cancelled = true;
  }, [accountPubkey, refreshKey, manualRefreshKey.value]);

  return (
    blockedPubkeys: blockedPubkeys.value,
    isLoading: isLoading.value,
    error: error.value,
    refresh: () => manualRefreshKey.value++,
  );
}
