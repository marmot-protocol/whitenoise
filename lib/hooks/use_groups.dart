import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;

final _logger = Logger('useGroups');

typedef GroupsState = ({
  List<groups_api.Group> groups,
  bool isLoading,
  String? error,
  void Function() clearError,
  Future<void> Function() refresh,
});

GroupsState useGroups({
  required String accountPubkey,
  Object? refreshKey,
}) {
  final groups = useState<List<groups_api.Group>>([]);
  final isLoading = useState(true);
  final error = useState<String?>(null);
  final fetchCounter = useRef(0);

  Future<void> fetchGroups() async {
    final token = ++fetchCounter.value;
    isLoading.value = true;
    error.value = null;
    try {
      final activeGroups = await groups_api.activeGroups(pubkey: accountPubkey);
      final nonDirectMessageGroups = <groups_api.Group>[];

      for (final group in activeGroups) {
        final isDirectMessage = await group.isDirectMessageType(accountPubkey: accountPubkey);
        if (!isDirectMessage) {
          nonDirectMessageGroups.add(group);
        }
      }

      if (token != fetchCounter.value) return;
      groups.value = nonDirectMessageGroups;
    } catch (e) {
      if (token != fetchCounter.value) return;
      _logger.severe('Failed to fetch groups: $e');
      error.value = 'groupLoadError';
    } finally {
      if (token == fetchCounter.value) {
        isLoading.value = false;
      }
    }
  }

  useEffect(() {
    fetchGroups();
    return () {
      fetchCounter.value++;
    };
  }, [accountPubkey, refreshKey]);

  void clearError() {
    error.value = null;
  }

  return (
    groups: groups.value,
    isLoading: isLoading.value,
    error: error.value,
    clearError: clearError,
    refresh: fetchGroups,
  );
}
