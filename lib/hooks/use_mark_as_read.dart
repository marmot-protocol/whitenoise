import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/account_groups.dart' as account_groups_api;

final _logger = Logger('useMarkAsRead');

typedef MarkAsReadResult = ({
  int? firstUnreadIndex,
  bool hasLoadedLastRead,
  void Function(String messageId) markMessageAsRead,
});

MarkAsReadResult useMarkAsRead({
  required String accountPubkey,
  required String groupId,
  required int messageCount,
  required int? Function(String messageId) getReversedIndex,
}) {
  final lastReadMessageId = useState<String?>(null);
  final hasLoadedLastRead = useState(false);

  Future<void> fetchLastReadMessageId() async {
    try {
      final accountGroup = await account_groups_api.getAccountGroup(
        accountPubkey: accountPubkey,
        mlsGroupId: groupId,
      );
      lastReadMessageId.value = accountGroup.lastReadMessageId;
    } catch (error) {
      _logger.severe('Failed to fetch last read message for group $groupId', error.toString());
    }
    hasLoadedLastRead.value = true;
  }

  useEffect(() {
    fetchLastReadMessageId();
    return null;
  }, [accountPubkey, groupId]);

  useEffect(() {
    if (hasLoadedLastRead.value) {
      fetchLastReadMessageId();
    }
    return null;
  }, [messageCount]);

  bool isMessageRead(String messageId) {
    if (messageId == lastReadMessageId.value) return true;
    final messageIndex = getReversedIndex(messageId);
    if (messageIndex == null) return true;

    final lastReadIndex = lastReadMessageId.value != null
        ? getReversedIndex(lastReadMessageId.value!)
        : null;

    return lastReadIndex != null && messageIndex >= lastReadIndex;
  }

  void markMessageAsRead(String messageId) {
    if (isMessageRead(messageId)) return;

    account_groups_api
        .markMessageRead(accountPubkey: accountPubkey, messageId: messageId)
        .then((_) {
          lastReadMessageId.value = messageId;
        })
        .onError((_, _) {});
  }

  int? computeFirstUnreadIndex() {
    if (!hasLoadedLastRead.value || messageCount == 0) return null;

    final lastReadId = lastReadMessageId.value;
    if (lastReadId == null) return messageCount - 1;

    final lastReadReversedIndex = getReversedIndex(lastReadId);
    if (lastReadReversedIndex == null) return null;

    return lastReadReversedIndex > 0 ? lastReadReversedIndex - 1 : null;
  }

  return (
    firstUnreadIndex: computeFirstUnreadIndex(),
    hasLoadedLastRead: hasLoadedLastRead.value,
    markMessageAsRead: markMessageAsRead,
  );
}
