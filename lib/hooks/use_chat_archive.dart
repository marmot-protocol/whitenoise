import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart';

final _logger = Logger('useChatArchive');

typedef ChatArchiveResult = ({
  bool isArchived,
  bool isLoading,
  bool isActionLoading,
  Future<void> Function() archive,
  Future<void> Function() unarchive,
});

ChatArchiveResult useChatArchive(String accountPubkey, String mlsGroupId) {
  final isArchived = useState<bool>(false);
  final isLoading = useState(true);
  final isActionLoading = useState(false);
  final isDisposed = useRef(false);

  Future<void> loadArchiveState() async {
    if (isDisposed.value) {
      return;
    }
    isLoading.value = true;
    try {
      final accountGroup = await getAccountGroup(
        accountPubkey: accountPubkey,
        mlsGroupId: mlsGroupId,
      );
      if (isDisposed.value) {
        return;
      }
      isArchived.value = accountGroup.archivedAt != null;
    } catch (e, st) {
      if (isDisposed.value) {
        return;
      }
      _logger.warning('Failed to load archive state for $mlsGroupId', e, st);
    } finally {
      if (!isDisposed.value) {
        isLoading.value = false;
      }
    }
  }

  useEffect(() {
    isDisposed.value = false;
    loadArchiveState();
    return () {
      isDisposed.value = true;
    };
  }, [accountPubkey, mlsGroupId]);

  Future<void> archive() async {
    final previousArchived = isArchived.value;
    isArchived.value = true;
    isActionLoading.value = true;
    try {
      await archiveChat(accountPubkey: accountPubkey, mlsGroupId: mlsGroupId);
    } catch (e, st) {
      if (!isDisposed.value) {
        isArchived.value = previousArchived;
      }
      _logger.severe('Failed to archive chat', e, st);
      rethrow;
    } finally {
      if (!isDisposed.value) {
        isActionLoading.value = false;
      }
    }
  }

  Future<void> unarchive() async {
    final previousArchived = isArchived.value;
    isArchived.value = false;
    isActionLoading.value = true;
    try {
      await unarchiveChat(accountPubkey: accountPubkey, mlsGroupId: mlsGroupId);
    } catch (e, st) {
      if (!isDisposed.value) {
        isArchived.value = previousArchived;
      }
      _logger.severe('Failed to unarchive chat', e, st);
      rethrow;
    } finally {
      if (!isDisposed.value) {
        isActionLoading.value = false;
      }
    }
  }

  return (
    isArchived: isArchived.value,
    isLoading: isLoading.value,
    isActionLoading: isActionLoading.value,
    archive: archive,
    unarchive: unarchive,
  );
}
