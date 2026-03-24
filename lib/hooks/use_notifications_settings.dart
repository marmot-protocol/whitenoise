import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;

final _logger = Logger('useNotificationsSettings');

const settingsLoadFailed = 'settings_load_failed';
const settingsUpdateFailed = 'settings_update_failed';

({
  AsyncSnapshot<accounts_api.AccountSettings?> settings,
  bool isUpdating,
  String? error,
  Future<void> Function(bool enabled) updateNotifications,
  void Function() clearError,
})
useNotificationsSettings(String accountPubkey) {
  final settingsFuture = useMemoized(
    () => accounts_api.accountSettings(pubkey: accountPubkey),
    [accountPubkey],
  );
  final snapshot = useFuture(settingsFuture);
  final isUpdating = useState(false);
  final error = useState<String?>(null);
  final currentSettings = useState<accounts_api.AccountSettings?>(null);
  final isMountedRef = useRef(true);

  useEffect(() {
    return () {
      isMountedRef.value = false;
    };
  }, const []);

  useEffect(() {
    if (snapshot.hasData) {
      currentSettings.value = snapshot.data;
    } else if (snapshot.hasError) {
      error.value = settingsLoadFailed;
    }
    return null;
  }, [snapshot.data, snapshot.hasError]);

  Future<void> updateNotifications(bool enabled) async {
    isUpdating.value = true;
    try {
      final updated = await accounts_api.updateNotificationsEnabled(
        pubkey: accountPubkey,
        enabled: enabled,
      );
      if (!isMountedRef.value) return;
      currentSettings.value = updated;
    } catch (e) {
      _logger.severe('Failed to update notifications', e);
      if (!isMountedRef.value) return;
      error.value = settingsUpdateFailed;
    } finally {
      if (isMountedRef.value) isUpdating.value = false;
    }
  }

  void clearError() {
    error.value = null;
  }

  return (
    settings: snapshot.hasData
        ? AsyncSnapshot.withData(ConnectionState.done, currentSettings.value)
        : snapshot,
    isUpdating: isUpdating.value,
    error: error.value,
    updateNotifications: updateNotifications,
    clearError: clearError,
  );
}
