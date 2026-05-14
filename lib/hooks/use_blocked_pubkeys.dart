import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise_frb/src/rust/api/mute_list.dart' as mute_list_api;

final _logger = Logger('useBlockedPubkeys');

typedef BlockedPubkeysState = ({
  Set<String> blockedPubkeys,
  bool isLoading,
  String? error,
  VoidCallback refresh,
});

BlockedPubkeysState useBlockedPubkeys(String accountPubkey, {int refreshKey = 0}) {
  final blockedPubkeys = useState<Set<String>>({});
  final isLoading = useState(true);
  final error = useState<String?>(null);
  final manualRefreshKey = useState(0);

  useEffect(() {
    var cancelled = false;
    isLoading.value = true;

    Future<void> fetchBlockedPubkeys() async {
      try {
        final entries = await mute_list_api.getBlockedUsers(accountPubkey: accountPubkey);
        if (cancelled) return;
        blockedPubkeys.value = entries.map((entry) => entry.mutedPubkey).toSet();
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
